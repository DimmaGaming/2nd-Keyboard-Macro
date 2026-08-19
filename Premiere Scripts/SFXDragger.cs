using System;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Markup;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Interop;
using System.Windows.Threading;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading;

namespace SFXDraggerWPF
{
    public class Program
    {
        // ── DWM imports for Mica / system backdrop ─────────────────────
        [DllImport("dwmapi.dll")]
        static extern int DwmSetWindowAttribute(IntPtr hwnd, int dwAttribute, ref int pvAttribute, int cbAttribute);

        const int DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
        const int DWMWA_SYSTEMBACKDROP_TYPE     = 38;

        // ── Focus-stealing imports ─────────────────────────────────────
        [DllImport("user32.dll")]
        static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

        [DllImport("kernel32.dll")]
        static extern uint GetCurrentThreadId();

        [DllImport("user32.dll")]
        static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

        [DllImport("user32.dll")]
        static extern IntPtr GetForegroundWindow();

        // ── Mouse simulation for synthetic drag-drop ───────────────────
        [DllImport("user32.dll")]
        static extern bool SetCursorPos(int X, int Y);

        [DllImport("user32.dll")]
        static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, UIntPtr dwExtraInfo);

        const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
        const uint MOUSEEVENTF_LEFTUP   = 0x0004;

        // AHK writes mouse position here before showing the window
        static readonly string MousePosFile = Path.Combine(Path.GetTempPath(), "sfx_mouse_pos.txt");

        [STAThread]
        public static void Main(string[] args)
        {
            string folder = @"D:\Dimma\Editing\AHK Sound Effects Folder";
            if (args.Length > 0)
                folder = string.Join(" ", args);

            int savedMouseX = 0, savedMouseY = 0;

            // ── XAML ───────────────────────────────────────────────────
            string xaml = @"<Window xmlns=""http://schemas.microsoft.com/winfx/2006/xaml/presentation""
        xmlns:x=""http://schemas.microsoft.com/winfx/2006/xaml""
        Title=""Instant SFX Dragger"" Height=""300"" Width=""450""
        WindowStyle=""None"" AllowsTransparency=""True"" Background=""Transparent""
        Topmost=""True"" WindowStartupLocation=""Manual""
        ShowInTaskbar=""False"">
    <Window.Resources>
        <Style TargetType=""ScrollBar"">
            <Setter Property=""Background"" Value=""Transparent""/>
            <Setter Property=""Width"" Value=""6""/>
            <Setter Property=""Template"">
                <Setter.Value>
                <ControlTemplate TargetType=""ScrollBar"">
                    <Grid Background=""Transparent"">
                        <Track Name=""PART_Track"" IsDirectionReversed=""true"">
                            <Track.Thumb>
                                <Thumb>
                                    <Thumb.Template>
                                        <ControlTemplate TargetType=""Thumb"">
                                            <Border Background=""#44FFFFFF"" CornerRadius=""3""/>
                                        </ControlTemplate>
                                    </Thumb.Template>
                                </Thumb>
                            </Track.Thumb>
                        </Track>
                    </Grid>
                </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType=""ListBoxItem"">
            <Setter Property=""Padding"" Value=""12,8""/>
            <Setter Property=""Foreground"" Value=""#DDDDDD""/>
            <Setter Property=""Template"">
                <Setter.Value>
                <ControlTemplate TargetType=""ListBoxItem"">
                    <Border Name=""Bd"" Background=""Transparent"" CornerRadius=""6"" Margin=""5,2"">
                        <ContentPresenter VerticalAlignment=""Center"" Margin=""{TemplateBinding Padding}""/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property=""IsSelected"" Value=""True"">
                            <Setter TargetName=""Bd"" Property=""Background"" Value=""#3A82F6""/>
                            <Setter Property=""Foreground"" Value=""White""/>
                        </Trigger>
                        <Trigger Property=""IsMouseOver"" Value=""True"">
                            <Setter TargetName=""Bd"" Property=""Background"" Value=""#1AFFFFFF""/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    
    <Border Name=""MainBorder"" Background=""#21494949"" CornerRadius=""12"" BorderBrush=""#22FFFFFF"" BorderThickness=""1"" Padding=""15"">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height=""Auto""/>
                <RowDefinition Height=""Auto""/>
                <RowDefinition Height=""*""/>
            </Grid.RowDefinitions>
            
            <Border Name=""TitleBar"" Grid.Row=""0"" Background=""Transparent"" Padding=""0,0,0,15"">
                <TextBlock Text=""Instant SFX Dragger"" Foreground=""#A0A0A0"" FontSize=""15"" 
                           HorizontalAlignment=""Center"" FontWeight=""SemiBold""
                           FontFamily=""San Francisco, Helvetica Neue, Inter, Segoe UI""/>
            </Border>
                       
            <Border Grid.Row=""1"" Background=""#165D5D5D"" CornerRadius=""8"" Padding=""10,8"" Margin=""0,0,0,15"">
                <TextBox Name=""SearchBox"" Background=""Transparent"" BorderThickness=""0"" Foreground=""White"" 
                         FontSize=""17"" FontFamily=""San Francisco, Helvetica Neue, Inter, Segoe UI"" CaretBrush=""White""/>
            </Border>
            
            <ListBox Name=""ResultList"" Grid.Row=""2"" Background=""Transparent"" BorderThickness=""0"" 
                     ScrollViewer.HorizontalScrollBarVisibility=""Disabled""
                     FontSize=""16"" FontFamily=""San Francisco, Helvetica Neue, Inter, Segoe UI""/>
        </Grid>
    </Border>
</Window>";

            Window window = (Window)XamlReader.Parse(xaml);
            TextBox searchBox = (TextBox)window.FindName("SearchBox");
            ListBox resultList = (ListBox)window.FindName("ResultList");
            Border titleBar = (Border)window.FindName("TitleBar");

            titleBar.MouseLeftButtonDown += (s, e) => window.DragMove();

            // ── File list (refreshed every time window is shown) ───────
            List<string> allFiles = new List<string>();

            Action RefreshFiles = () => {
                allFiles.Clear();
                if (Directory.Exists(folder))
                {
                    allFiles.AddRange(Directory.GetFiles(folder));
                }
            };

            RefreshFiles();

            Action<string> FilterList = (query) => {
                resultList.Items.Clear();
                var matches = allFiles.Where(f => Path.GetFileNameWithoutExtension(f).IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0).ToArray();
                foreach (var m in matches) resultList.Items.Add(Path.GetFileNameWithoutExtension(m));
                if (resultList.Items.Count > 0) resultList.SelectedIndex = 0;
            };

            FilterList("");

            searchBox.TextChanged += (s, e) => FilterList(searchBox.Text);

            // ── Read mouse position from AHK's temp file ───────────────
            Action ReadMousePos = () => {
                try
                {
                    string[] lines = File.ReadAllLines(MousePosFile);
                    if (lines.Length >= 2)
                    {
                        int.TryParse(lines[0].Trim(), out savedMouseX);
                        int.TryParse(lines[1].Trim(), out savedMouseY);
                    }
                }
                catch { }
            };

            // ── Position window near cursor ────────────────────────────
            Action PositionNearCursor = () => {
                double dpiX = 1.0;
                double dpiY = 1.0;
                
                var source = PresentationSource.FromVisual(window);
                if (source != null && source.CompositionTarget != null)
                {
                    dpiX = source.CompositionTarget.TransformFromDevice.M11;
                    dpiY = source.CompositionTarget.TransformFromDevice.M22;
                }

                double logicalX = savedMouseX * dpiX;
                double logicalY = savedMouseY * dpiY;

                double winW = window.Width;
                double winH = window.Height;
                double left = logicalX + 20;
                double top  = logicalY - 60;

                // Clamp to screen bounds
                double scrW = SystemParameters.VirtualScreenWidth;
                double scrH = SystemParameters.VirtualScreenHeight;
                double scrL = SystemParameters.VirtualScreenLeft;
                double scrT = SystemParameters.VirtualScreenTop;

                if (left < scrL) left = scrL;
                if (top  < scrT) top  = scrT;
                if (left + winW > scrL + scrW) left = scrL + scrW - winW;
                if (top  + winH > scrT + scrH) top  = scrT + scrH - winH;

                window.Left = left;
                window.Top  = top;
            };

            // ── Apply: Trigger AHK to perform physical drag ────────────
            Action ApplySelected = () => {
                if (resultList.SelectedItem == null) return;

                // Ensure item is generated
                resultList.UpdateLayout();
                ListBoxItem item = (ListBoxItem)resultList.ItemContainerGenerator.ContainerFromItem(resultList.SelectedItem);
                
                if (item != null)
                {
                    // Get logical position relative to window (15px from left, 10px from top)
                    Point relativePoint = item.TranslatePoint(new Point(15, 10), window);
                    var source = PresentationSource.FromVisual(window);
                    
                    if (source != null && source.CompositionTarget != null)
                    {
                        // Explicitly calculate physical pixels to ensure AHK gets the exact screen location
                        Matrix m = source.CompositionTarget.TransformToDevice;
                        double physX = (window.Left + relativePoint.X) * m.M11;
                        double physY = (window.Top + relativePoint.Y) * m.M22;

                        string triggerFile = Path.Combine(Path.GetTempPath(), "sfx_drag_trigger.txt");
                        File.WriteAllText(triggerFile, ((int)physX).ToString() + "\n" + ((int)physY).ToString());
                    }
                }
            };

            // ── Keyboard: SearchBox ────────────────────────────────────
            searchBox.PreviewKeyDown += (s, e) => {
                Key actualKey = (e.Key == Key.System) ? e.SystemKey : e.Key;

                if (actualKey == Key.Down || (actualKey == Key.S && Keyboard.Modifiers == ModifierKeys.Alt) || (actualKey == Key.Tab && Keyboard.Modifiers == ModifierKeys.None)) {
                    e.Handled = true;
                    if (resultList.Items.Count > 0) {
                        if (resultList.SelectedIndex < resultList.Items.Count - 1) resultList.SelectedIndex++;
                        resultList.ScrollIntoView(resultList.SelectedItem);
                    }
                }
                else if (actualKey == Key.Up || (actualKey == Key.W && Keyboard.Modifiers == ModifierKeys.Alt) || (actualKey == Key.Tab && Keyboard.Modifiers == ModifierKeys.Shift)) {
                    e.Handled = true;
                    if (resultList.Items.Count > 0) {
                        if (resultList.SelectedIndex > 0) resultList.SelectedIndex--;
                        resultList.ScrollIntoView(resultList.SelectedItem);
                    }
                }
                else if (actualKey == Key.Enter || (actualKey == Key.A && Keyboard.Modifiers == ModifierKeys.Alt)) {
                    e.Handled = true;
                    ApplySelected();
                }
            };

            // ── Keyboard: ResultList ───────────────────────────────────
            resultList.PreviewKeyDown += (s, e) => {
                Key actualKey = (e.Key == Key.System) ? e.SystemKey : e.Key;

                if (actualKey == Key.Up || (actualKey == Key.W && Keyboard.Modifiers == ModifierKeys.Alt) || (actualKey == Key.Tab && Keyboard.Modifiers == ModifierKeys.Shift)) {
                    e.Handled = true;
                    if (resultList.SelectedIndex > 0) resultList.SelectedIndex--;
                    resultList.ScrollIntoView(resultList.SelectedItem);
                }
                else if (actualKey == Key.Down || (actualKey == Key.S && Keyboard.Modifiers == ModifierKeys.Alt) || (actualKey == Key.Tab && Keyboard.Modifiers == ModifierKeys.None)) {
                    e.Handled = true;
                    if (resultList.SelectedIndex < resultList.Items.Count - 1) resultList.SelectedIndex++;
                    resultList.ScrollIntoView(resultList.SelectedItem);
                }
                else if (actualKey == Key.Enter || (actualKey == Key.A && Keyboard.Modifiers == ModifierKeys.Alt)) {
                    e.Handled = true;
                    ApplySelected();
                }
            };

            // ── Keyboard: Window-level close ───────────────────────────
            window.PreviewKeyDown += (s, e) => {
                Key actualKey = (e.Key == Key.System) ? e.SystemKey : e.Key;

                if (actualKey == Key.Escape || (actualKey == Key.Q && Keyboard.Modifiers == ModifierKeys.Alt)) {
                    e.Handled = true;
                    window.Hide();
                }
            };

            // ── Mouse drag (manual drag still works) ───────────────────
            Point startPoint = new Point();
            bool isDragging = false;

            resultList.PreviewMouseLeftButtonDown += (s, e) => {
                startPoint = e.GetPosition(null);
            };

            resultList.PreviewMouseMove += (s, e) => {
                if (e.LeftButton == MouseButtonState.Pressed && !isDragging)
                {
                    Point position = e.GetPosition(null);
                    if (Math.Abs(position.X - startPoint.X) > SystemParameters.MinimumHorizontalDragDistance ||
                        Math.Abs(position.Y - startPoint.Y) > SystemParameters.MinimumVerticalDragDistance)
                    {
                        var listBoxItem = FindVisualParent<ListBoxItem>((DependencyObject)e.OriginalSource);
                        if (listBoxItem != null)
                        {
                            isDragging = true;
                            string fileName = listBoxItem.Content.ToString();
                            string filePath = allFiles.FirstOrDefault(f => Path.GetFileNameWithoutExtension(f) == fileName);
                            
                            if (filePath != null)
                            {
                                string[] files = new string[] { filePath };
                                DataObject data = new DataObject(DataFormats.FileDrop, files);
                                DragDrop.DoDragDrop(listBoxItem, data, DragDropEffects.Copy);
                                window.Hide();
                            }
                            isDragging = false;
                        }
                    }
                }
            };

            // ── On show: refresh files, read mouse pos, reposition ─────
            window.IsVisibleChanged += (s, e) => {
                if ((bool)e.NewValue) {
                    ReadMousePos();
                    PositionNearCursor();
                    RefreshFiles();
                    searchBox.Clear();
                    FilterList("");
                    ForceFocusWindow(window, searchBox);
                }
            };

            // Apply DWM Mica backdrop and setup message hooks
            window.SourceInitialized += (s, e) => {
                var hwnd = new WindowInteropHelper(window).Handle;
                TryEnableMica(hwnd);

                HwndSource.FromHwnd(hwnd).AddHook((IntPtr h, int msg, IntPtr wp, IntPtr lp, ref bool handled) => {
                    if (msg == WM_SHOWME)
                    {
                        window.Show();
                        window.Activate();
                        handled = true;
                    }
                    else if (msg == WM_HIDEME)
                    {
                        window.Hide();
                        handled = true;
                    }
                    return IntPtr.Zero;
                });

                // Position on first launch too
                ReadMousePos();
                PositionNearCursor();
            };

            // Ensure focus on activation
            window.Activated += (s, e) => {
                ForceFocusWindow(window, searchBox);
            };

            window.ContentRendered += (s, e) => {
                ForceFocusWindow(window, searchBox);
            };

            window.Closing += (s, e) => {
                e.Cancel = true;
                window.Hide();
            };

            Application app = new Application();
            app.Run(window);
        }



        const int WM_USER = 0x0400;
        const int WM_SHOWME = WM_USER + 1;
        const int WM_HIDEME = WM_USER + 2;

        static void TryEnableMica(IntPtr hwnd)
        {
            try
            {
                int darkMode = 1;
                DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, ref darkMode, sizeof(int));

                int backdropType = 2;
                DwmSetWindowAttribute(hwnd, DWMWA_SYSTEMBACKDROP_TYPE, ref backdropType, sizeof(int));
            }
            catch { }
        }

        static void ForceFocusWindow(Window window, TextBox searchBox)
        {
            var hwnd = new WindowInteropHelper(window).Handle;
            if (hwnd == IntPtr.Zero) return;

            IntPtr foregroundHwnd = GetForegroundWindow();
            uint pid;
            uint foregroundThread = GetWindowThreadProcessId(foregroundHwnd, out pid);
            uint currentThread = GetCurrentThreadId();

            if (foregroundThread != currentThread)
                AttachThreadInput(foregroundThread, currentThread, true);

            SetForegroundWindow(hwnd);

            if (foregroundThread != currentThread)
                AttachThreadInput(foregroundThread, currentThread, false);

            searchBox.Focus();
            Keyboard.Focus(searchBox);

            window.Dispatcher.BeginInvoke(DispatcherPriority.Input, new Action(() => {
                searchBox.Focus();
                Keyboard.Focus(searchBox);
            }));
        }

        private static T FindVisualParent<T>(DependencyObject child) where T : DependencyObject
        {
            DependencyObject parentObject = VisualTreeHelper.GetParent(child);
            if (parentObject == null) return null;
            T parent = parentObject as T;
            if (parent != null) return parent;
            else return FindVisualParent<T>(parentObject);
        }
    }
}
