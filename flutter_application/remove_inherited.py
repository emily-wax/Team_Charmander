import sys
import os
from bs4 import BeautifulSoup

def hide_inherited_members(file_path):
    # Read the HTML file
    with open(file_path, 'r', encoding='utf-8') as file:
        html_content = file.read()

    # Parse the HTML content
    soup = BeautifulSoup(html_content, 'html.parser')

    # Find all elements with class 'inherited' and remove them
    inherited_elements = soup.find_all(class_='inherited')
    for element in inherited_elements:
        element.decompose()

    # Save the modified HTML content to the same file
    with open(file_path, 'w', encoding='utf-8') as file:
        file.write(str(soup))

    print(f"Modified HTML file: '{file_path}'")

def process_directory(directory):
    # Traverse the directory and its subdirectories
    for root, dirs, files in os.walk(directory):
        for file in files:
            # Check if the file has a .html extension
            if file.endswith(".html"):
                file_path = os.path.join(root, file)
                hide_inherited_members(file_path)
            else:
                print(f"Skipping non-HTML file: '{file}'")

if __name__ == "__main__":
    # Check if a directory path is provided as a command-line argument
    if len(sys.argv) != 2:
        print("Usage: python hide_inherited_members.py <directory>")
        sys.exit(1)

    # Get the directory path from the command-line arguments
    directory = sys.argv[1]

    # Check if the directory exists
    if not os.path.exists(directory):
        print(f"Directory '{directory}' not found.")
        sys.exit(1)

    # Call the function to process the directory
    process_directory(directory)
