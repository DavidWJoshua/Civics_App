import os
import torch
from flask import Flask, request, jsonify
from torchvision import transforms
from PIL import Image
import io

from model import CivicClassifierEffNet
from config import *

app = Flask(__name__)

# Load model
device = "cuda" if torch.cuda.is_available() else "cpu"
model = CivicClassifierEffNet().to(device)

# Adjusted path for root ml/ directory
ACTUAL_MODEL_PATH = os.path.join("model", "civic_model.pth")
if not os.path.exists(ACTUAL_MODEL_PATH):
    # Fallback if somehow not in subdirectory
    ACTUAL_MODEL_PATH = "civic_model.pth"

model.load_state_dict(torch.load(ACTUAL_MODEL_PATH, map_location=device))
model.eval()

transform = transforms.Compose([
    transforms.Resize((IMAGE_SIZE, IMAGE_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    )
])

@app.route('/predict', methods=['POST'])
def predict():
    if 'image' not in request.files:
        return jsonify({"error": "No image provided"}), 400
    
    file = request.files['image']
    img_bytes = file.read()
    image = Image.open(io.BytesIO(img_bytes)).convert("RGB")
    image = transform(image).unsqueeze(0).to(device)

    with torch.no_grad():
        cat_out, sev_out = model(image)

    category = INV_CATEGORY_MAP[cat_out.argmax().item()]
    
    if category != "Others":
        severity = INV_SEVERITY_MAP[sev_out.argmax().item()]
    else:
        severity = "NA"

    return jsonify({
        "category": category,
        "severity": severity
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
