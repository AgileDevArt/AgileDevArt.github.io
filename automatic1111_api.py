import bpy
import base64
import re
import requests
from ... import (
    config,
    operators,
    utils,
)

API_ENDPOINT = "api/generate"
API_VERSION = 5

# CORE FUNCTIONS:

def send_to_api(params, img_file, filename_prefix):

    # map the generic params to the specific ones for the Automatic1111 API
    map_params(params)

    # add a base 64 encoded image to the params
    params["init_img"] = base64.b64encode(img_file.read()).decode()
    img_file.close()
    
    # create the headers
    headers = {
        "User-Agent": "Blender/" + bpy.app.version_string,
        "Accept": "*/*",
        "Content-Type": "application/json",
    }
     
    # prepare the server url
    server_url = utils.local_sd_url().rstrip("/").strip()
    server_url = server_url + "/" if not re.match(".*/$", server_url) else server_url
    server_url = re.sub("http://", "https://", server_url)
    server_url = server_url + API_ENDPOINT

    # send the API request
    try:
        response = requests.post(server_url, json=params, headers=headers, timeout=utils.local_sd_timeout())
    except requests.exceptions.ConnectionError:
        return operators.handle_error(f"The local Stable Diffusion server couldn't be found. It's either not running, or it's running at a different location than what you specified in the add-on preferences. [Get help]({config.HELP_WITH_LOCAL_INSTALLATION_URL})")
    except requests.exceptions.MissingSchema:
        return operators.handle_error(f"The url for your local Stable Diffusion server is invalid. Please set it correctly in the add-on preferences. [Get help]({config.HELP_WITH_LOCAL_INSTALLATION_URL})")
    except requests.exceptions.ReadTimeout:
        return operators.handle_error("The local Stable Diffusion server timed out. Set a longer timeout in AI Render preferences, or use a smaller image size.")

    # handle the response
    if response.status_code == 200:
        return handle_api_success(response, filename_prefix)
    else:
        return handle_api_error(response)


def handle_api_success(response, filename_prefix):

    # ensure we have the type of response we are expecting
    try:
        response_obj = response.json()
        base64_img = response_obj["images"][0]["image"]
    except:
        print("Automatic1111 response content: ")
        print(response.content)
        return operators.handle_error("Received an unexpected response from the Automatic1111 Stable Diffusion server.")

    # create a temp file
    try:
        output_file = utils.create_temp_file(filename_prefix + "-")
    except:
        return operators.handle_error("Couldn't create a temp file to save image.")

    # decode base64 image
    try:
        img_binary = base64.b64decode(base64_img)
    except:
        return operators.handle_error("Couldn't decode base64 image from the Automatic1111 Stable Diffusion server.")

    # save the image to the temp file
    try:
        with open(output_file, 'wb') as file:
            file.write(img_binary)
    except:
        return operators.handle_error("Couldn't write to temp file.")


    # return the temp file
    return output_file


def handle_api_error(response):
    if response.status_code in [403, 404]:
        return operators.handle_error("It looks like the web server this add-on relies on is missing. It's possible this is temporary, and you can try again later.")
    elif response.status_code == 405:
        return operators.handle_error("Plugin and stable-diffusion server don't match. Please update the plugin. If the error still occurs, please reopen the colab notebook.")
    # handle all other errors
    return operators.handle_error(f"An unknown error occurred. Code: {str(response.status_code)}")


def get_samplers():
    # NOTE: Keep the number values (fourth item in the tuples) in sync with DreamStudio's
    # values (in dreamstudio_apy.py). These act like an internal unique ID for Blender
    # to use when switching between the lists.
    return [
        ('Euler', 'Euler', '', 10),
        ('Euler a', 'Euler a', '', 20),
        ('Heun', 'Heun', '', 30),
        ('DPM2', 'DPM2', '', 40),
        ('DPM2 a', 'DPM2 a', '', 50),
        ('LMS', 'LMS', '', 60),
        ('DPM fast', 'DPM fast', '', 70),
        ('DPM adaptive', 'DPM adaptive', '', 80),
        ('DPM++ 2S a Karras', 'DPM++ 2S a Karras', '', 90),
        ('DPM++ 2M Karras', 'DPM++ 2M Karras', '', 100),
        ('DPM++ 2S a', 'DPM++ 2S a', '', 110),
        ('DPM++ 2M', 'DPM++ 2M', '', 120),
        ('PLMS', 'PLMS', '', 200),
        ('DDIM', 'DDIM', '', 210),
    ]

def default_sampler():
    return 'LMS'


# SUPPORT FUNCTIONS:

def map_params(params):
    params["init_strength"] = params["image_similarity"]
    params["prompt_strength"] = params["cfg_scale"]
    params["mode"] = "MODE_IMG2IMG"
    params["image_count"] = 1
    params["api_version"] = API_VERSION
