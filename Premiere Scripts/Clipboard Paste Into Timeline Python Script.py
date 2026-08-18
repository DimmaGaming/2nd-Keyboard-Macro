import os
import sys
from datetime import datetime
from PIL import ImageGrab, Image
import traceback

def main():
    # 1. Establish Folder
    if len(sys.argv) > 1:
        target_folder = sys.argv[1]
    else:
        target_folder = r"D:\Dimma\Editing\All Editing Images Folder"

    if not os.path.exists(target_folder):
        os.makedirs(target_folder)

    # Setup Logging
    log_path = os.path.join(target_folder, "python_error_log.txt")

    def write_log(message):
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {message}\n")

    write_log("--- AHK Triggered Python Script ---")

    # 2. Grab Clipboard and Save
    try:
        clip_data = ImageGrab.grabclipboard()

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"Clipboard_{timestamp}.png"
        full_path = os.path.join(target_folder, filename)

        if isinstance(clip_data, list) and len(clip_data) > 0:
            try:
                img = Image.open(clip_data[0])
                img.save(full_path, "PNG")
                write_log(f"SUCCESS: Copied file converted and saved: {full_path}")
            except Exception as e:
                write_log(f"ERROR converting file: {e}")

        elif clip_data is not None:
            clip_data.save(full_path, "PNG")
            write_log(f"SUCCESS: Saved clipboard image pixels: {full_path}")

        else:
            write_log("FAIL: No image found in the clipboard. 'clip_data' returned None.")

    except Exception as e:
        write_log(f"CRITICAL CRASH:\n{traceback.format_exc()}")

if __name__ == "__main__":
    main()