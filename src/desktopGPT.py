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
import cv2
import numpy as np
import pytesseract
import requests
import clipboard
from plyer import notification



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
        notification.notify(app_name="Desktop GPT",
                            title='Error',
                            message=NETWORK_ERROR_MSG,
                            app_icon=f'{PATH}/img/error.png',
                            timeout=TIMEOUT)
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

    desktop = os.environ.get('DESKTOP_SESSION')
    if 'plasma' in desktop:
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

    img = cv2.imread('/tmp/screenshot.png', 0)
    if np.average(img[:img.shape[0] // 10]) < 128:
        img = cv2.bitwise_not(img)
    return pytesseract.image_to_string(img, config=r'--oem 3 --psm 6')[:-1]


def generate_text(text):
    """
    Generates text response for a given prompt using API and displays a notification.

    Returns:
    None
    """

    prompt = f'{INSTRUCTION}\n{text}'
    headers = {'Content-Type': 'application/json', 'Authorization': f'Bearer {API_KEY}'}
    data = {'prompt': prompt,
            'model': MODEL,
            'max_tokens': MAX_TOKENS,
            'n': N,
            'stop': STOP,
            'temperature': TEMPERATURE}

    result = post_request(url=ENDPOINT, headers=headers, data=data)
    json_data = result.get('json')

    if json_data:
        string = json_data['choices'][0]['text'].strip()
        clipboard.copy(f'Question:\n{text}\n\n{string}')
        string = string.replace(':\n', ': ')
        title, msg = string.split('\n', 1)
        note = {'title': title, 'message': msg, 'icon': 'desktopGPT'}
    else:
        note = {'title': 'Error', 'message': NO_RESPONSE_MSG, 'icon': 'error'}

    notification.notify(app_name='Desktop GPT',
                        title=note["title"],
                        message=note["message"],
                        app_icon=f'{PATH}/img/{note["icon"]}.png',
                        timeout=TIMEOUT)


# PATH = os.getcwd()
PATH = os.path.dirname(sys.executable)


try:
    config = ConfigParser()
    config.read(f'{PATH}/config.ini')
    API_KEY = config['OPENAI']['API_KEY']
    MAX_TOKENS = config.getint('OPENAI', 'MAX_TOKENS', fallback=16)
    N = config.getint('OPENAI', 'N', fallback=1)
    TEMPERATURE = config.getfloat('OPENAI', 'TEMPERATURE', fallback=1)
    TIMEOUT = config.getint('NOTIFICATION', 'TIMEOUT', fallback=5)
except Exception as err:
    message = f'{err} was not found in your configuration file,' \
              f'or it may not have been configured correctly.'
    notification.notify(app_name="Desktop GPT",
                        title='Error',
                        message=message,
                        app_icon=f'{PATH}/img/error.png',
                        timeout=10)
else:
    ENDPOINT = config.get('OPENAI', 'ENDPOINT', fallback='https://api.openai.com/v1/completions')
    MODEL = config.get('OPENAI', 'MODEL', fallback='text-davinci-002')
    STOP = config.get('OPENAI', 'STOP', fallback=None)
    INSTRUCTION = config.get('OPENAI', 'INSTRUCTION', fallback='')
    NETWORK_ERROR_MSG = config.get('NOTIFICATION', 'NETWORK_ERROR_MSG', fallback='Network Error Occurred')
    NO_RESPONSE_MSG = config.get('NOTIFICATION', 'NO_RESPONSE_MSG', fallback='')

    take_screenshot()
    generate_text(read_text_from_image())
