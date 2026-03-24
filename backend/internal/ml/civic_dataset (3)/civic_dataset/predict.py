import torch
from torchvision import transforms
from PIL import Image

from model import CivicClassifierEffNet
from config import *


device = "cuda" if torch.cuda.is_available() else "cpu"

transform = transforms.Compose([
    transforms.Resize((IMAGE_SIZE, IMAGE_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    )
])

model = CivicClassifierEffNet().to(device)
model.load_state_dict(torch.load(MODEL_PATH, map_location=device))
model.eval()


def predict_image(image_path):
    image = Image.open(image_path).convert("RGB")
    image = transform(image).unsqueeze(0).to(device)

    with torch.no_grad():
        cat_out, sev_out = model(image)

    category = INV_CATEGORY_MAP[cat_out.argmax().item()]

    if category != "Others":
        severity = INV_SEVERITY_MAP[sev_out.argmax().item()]
    else:
        severity = "NA"

    return category, severity


if __name__ == "__main__":
    category, severity = predict_image("test.jpg.jpeg")
    print("Predicted Category:", category)
    print("Predicted Severity:", severity)
