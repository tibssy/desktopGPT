"""
Program for text recognition and response from a screenshot.

This program provides a function for taking screenshots from mouse selection,
extracting the text from the screenshot using pytesseract,
sending the text to OpenAI API for a response, writing both the input text and
the response text to the clipboard, and displaying the response text as
a desktop notification. It is compatible with Linux desktops,
including both KDE/Plasma and Gnome.
"""

import os
import sys
import subprocess
from configparser import ConfigParser
from PIL import Image
import numpy as np
import pytesseract
import requests
import clipboard
from notifypy import Notify


def send_notification(note):
    """
    Sends a desktop notification with the given title, message, and icon.

    Args:
        note (dict): A dictionary containing the keys "title", "message", and "icon".

    Returns:
        None
    """

    notification = Notify()
    notification.application_name = "Desktop GPT"
    notification.title = note["title"]
    notification.message = note["message"]
    notification.icon = f'{PATH}/img/{note["icon"]}.png'
    notification.send(block=False)


def post_request(**kwargs):
    """
    Sends a POST request to a specified URL.

    This function takes in a dictionary of keyword arguments
    which should include 'url', 'headers', and 'data'
    to send a POST request to the specified URL.
    In case of a connection error,
    a notification with an error message is displayed and the program exits.

    Returns:
    dict: A dictionary containing the status code and JSON response of the request.
    """

    url = kwargs.get('url')
    headers = kwargs.get('headers')
    data = kwargs.get('data')
    try:
        response = requests.post(url, headers=headers, json=data, timeout=20)
    except requests.exceptions.RequestException as err:
        send_notification({'title': 'Error', 'message': NETWORK_ERROR_MSG, 'icon': 'error'})
        raise SystemExit(err)

    result = {'code': response.status_code}
    if result['code'] == 200:
        result['json'] = response.json()
    return result


def take_screenshot():
    """
    Takes a screenshot of the desktop.

    This function determines the desktop environment and uses either
    the 'spectacle' or 'gnome-screenshot' command line tool
    to take a screenshot and save it to the file '/tmp/screenshot.png'.

    Returns:
    None
    """

    if 'plasma' in DESKTOP_ENV:
        subprocess.call(['spectacle', '-rbno', '/tmp/screenshot.png'])
    else:
        subprocess.call(['gnome-screenshot', '-af', '/tmp/screenshot.png'])


def read_text_from_image():
    """
    Extracts text from an image file.

    This function reads an image file '/tmp/screenshot.png' and converts it to a grayscale
    image. If the average pixel value of the top 10% of the image is less than 128, the
    image is inverted. The text in the image is then extracted using optical character
    recognition (OCR) with pytesseract.

    Returns:
    str: The extracted text from the image, with the last character removed.
    """

    img = np.array(Image.open('/tmp/screenshot.png').convert('L'))
    if np.average(img[:img.shape[0] // 10]) < 128:
        img = 255 - img
    return pytesseract.image_to_string(img, config=r'--oem 3 --psm 6')[:-1]


def raw_to_notify_clip_data(text_in, raw_text):
    """
    Extracts structured data from a raw text string and formats it
    for clipboard and notification messages.

    Args:
        text_in (str): The original user input text.
        raw_text (str): The raw text string to extract data from.

    Returns:
        A dictionary with two keys:
        - 'notify_msg': A dictionary with keys 'title', 'message', and 'icon' to display a notification.
        - 'clipboard_msg': A formatted string to copy to the clipboard.

    The function looks for the first occurrence of the string 'Title' in the raw text, then extracts
    categories and values until the next 'Title' or the end of the string. The resulting dictionary
    is used to populate the notification.
    """

    start_point = raw_text.find('Title')

    if start_point != -1:
        keys = [category.strip('"') for category in CATEGORIES.split(', ')]

        cleaned_text = raw_text[start_point:].strip()
        indices = [cleaned_text.find(key) for key in keys if key in cleaned_text]
        dict_text = dict([cleaned_text[i:j].split(':', 1) for i, j in zip(indices, indices[1:] + [None])])

        title = dict_text.pop('Title', 'About').strip()
        reference = dict_text.pop('Reference', '').strip()
        reference_title = dict_text.pop('Reference Title', title).strip()
        msg = ''.join(f' - {key.strip()}:\n{value.strip()}\n\n' for key, value in dict_text.items())

        clipboard_msg = f' - Question:\n{text_in}\n\n - Title:\n{title}\n\n{msg}'
        notify_msg = {'title': title, 'message': f'{msg}', 'icon': 'desktopGPT'}

        if reference:
            clipboard_msg += f' - Reference:\n{reference}'
            if 'plasma' in DESKTOP_ENV and '\n' not in reference and '\n' not in reference_title:
                reference = f'<a href="{reference}">{reference_title}</a>'

            notify_msg['message'] += f'\n - Reference:\n{reference}'

    else:
        clipboard_msg = f' - Question:\n{text_in}\n\n {raw_text}'
        notify_msg = {'title': 'About', 'message': f'{raw_text}', 'icon': 'desktopGPT'}

    return {'notify_msg': notify_msg, 'clipboard_msg': clipboard_msg}


def generate_text(text):
    """
    Generates text response for a given prompt using API and displays a notification.

    Returns:
    None
    """
    categories = f'"Title", {RESPONSE_KEYS}, "Reference", "Reference Title"'
    prompt = f'{INSTRUCTION} {categories}\n{text}'
    headers = {'Content-Type': 'application/json', 'Authorization': f'Bearer {API_KEY}'}
    data = {'prompt': prompt,
            'model': MODEL,
            'max_tokens': MAX_TOKENS,
            'n': N,
            'stop': STOP,
            'temperature': TEMPERATURE}

    result = post_request(url=ENDPOINT, headers=headers, data=data)
    json_data = result.get('json')
    print(f'json_data:\n{json_data}')

    if json_data:
        return json_data['choices'][0]['text']


# PATH = os.getcwd()
PATH = os.path.dirname(sys.executable)
DESKTOP_ENV = os.environ.get('DESKTOP_SESSION')


try:
    config = ConfigParser()
    config.read(f'{PATH}/config.ini')
    API_KEY = config['OPENAI']['API_KEY']
    MAX_TOKENS = config.getint('OPENAI', 'MAX_TOKENS', fallback=16)
    N = config.getint('OPENAI', 'N', fallback=1)
    TEMPERATURE = config.getfloat('OPENAI', 'TEMPERATURE', fallback=0.5)
except Exception as err:
    message = f'{err} was not found in your configuration file,' \
              f'or it may not have been configured correctly.'

    send_notification({'title': 'Error', 'message': message, 'icon': 'error'})
else:
    ENDPOINT = config.get('OPENAI', 'ENDPOINT', fallback='https://api.openai.com/v1/completions')
    MODEL = config.get('OPENAI', 'MODEL', fallback='text-davinci-002')
    STOP = config.get('OPENAI', 'STOP', fallback=None)
    RESPONSE_KEYS = config.get('OPENAI', 'RESPONSE_KEYS', fallback='"About"')
    NETWORK_ERROR_MSG = config.get('NOTIFICATION', 'NETWORK_ERROR_MSG', fallback='Network Error Occurred')
    NO_RESPONSE_MSG = config.get('NOTIFICATION', 'NO_RESPONSE_MSG', fallback='')

    INSTRUCTION = 'Separate your answer based on these keys:'
    CATEGORIES = f'"Title", {RESPONSE_KEYS}, "Reference", "Reference Title"'

    take_screenshot()
    question = read_text_from_image()
    answer = generate_text(question)

    if answer:
        data_out = raw_to_notify_clip_data(question, answer)
        send_notification(data_out.get('notify_msg'))
        clipboard.copy(data_out.get('clipboard_msg'))
    else:
        send_notification({'title': 'Error', 'message': NO_RESPONSE_MSG, 'icon': 'error'})
