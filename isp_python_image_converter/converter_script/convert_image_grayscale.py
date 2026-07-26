import argparse
import os
from PIL import Image
import numpy as np
from pathlib import Path

def process_images(input_folder, output_folder, target_width, target_height):
    os.makedirs(output_folder, exist_ok=True)
    supported_formats = ('.jpg', '.jpeg', '.png', '.bmp', '.gif', '.tiff', '.webp')

    image_files = []
    for file in os.listdir(input_folder):
        if file.lower().endswith(supported_formats):
            image_files.append(file)
    
    if not image_files:
        print("No images in {}".format(input_folder))
        return

    print("Images found: {}".format(len(image_files)))
    print("Target size: {}x{}".format(target_width, target_height))
    print("-" * 50)

    for idx, filename in enumerate(image_files, 1):
        try:
            input_path = os.path.join(input_folder, filename)

            with Image.open(input_path) as img:
                img_resized = img.resize((target_width, target_height), Image.Resampling.LANCZOS)
                
                img_gray = img_resized.convert('L')
                
                pixel_array = np.array(img_gray, dtype=np.uint8)
                
                base_name = os.path.splitext(filename)[0]
                output_filename = "{}_{}_{}.data".format(base_name, target_width, target_height)
                output_path = os.path.join(output_folder, output_filename)
                
                pixel_array.tofile(output_path)
        except Exception as e:
            print("[{}/{}]  Processing error {}: {}".format(idx, len(image_files), filename, e))



def main():
    parser = argparse.ArgumentParser(
                                        prog='<<<Python image converter>>>',
                                        description='Converter creates the file (.data) containing raw black and white image pixels brightness values as it is.\n' \
                                        'This file can be used in testbenches to test modules.\n',
                                        epilog='Use it to generate images to test ISP modules.'
                                     )
    
    parser.add_argument('-v', '--verbose', help='Verbose mode for the debugging purposes: Y for verbose', type=str, default='N')
    parser.add_argument('-input_folder', help='Path to the folder with images to be converted', type=str, default=None)
    parser.add_argument('-output_folder', help='Path to the folder with converted images', type=str, default=None)
    parser.add_argument('-output_width', help='Width of the converted image', type=int, default=None)
    parser.add_argument('-output_height', help='Height of the converted image', type=int, default=None)

    args = parser.parse_args()

    process_images(args.input_folder, args.output_folder, args.output_width, args.output_height)


if __name__ == "__main__":
    main()
