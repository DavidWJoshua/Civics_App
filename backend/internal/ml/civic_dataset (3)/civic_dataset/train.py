import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from torchvision import transforms

from dataset import CivicDataset
from model import CivicClassifierEffNet
from config import *


def main():
    device = "cuda" if torch.cuda.is_available() else "cpu"

    transform = transforms.Compose([
        transforms.Resize((IMAGE_SIZE, IMAGE_SIZE)),
        transforms.ToTensor(),
        transforms.Normalize(
            mean=[0.485, 0.456, 0.406],
            std=[0.229, 0.224, 0.225]
        )
    ])

    dataset = CivicDataset(DATASET_PATH, transform)
    train_loader = DataLoader(dataset, batch_size=BATCH_SIZE, shuffle=True)

    print("Total images:", len(dataset))

    model = CivicClassifierEffNet().to(device)

    criterion_cat = nn.CrossEntropyLoss()
    criterion_sev = nn.CrossEntropyLoss(ignore_index=-1)

    optimizer = torch.optim.Adam(model.parameters(), lr=LR)

    for epoch in range(EPOCHS):
        model.train()
        total_loss = 0

        for images, cat_labels, sev_labels in train_loader:
            images = images.to(device)
            cat_labels = cat_labels.to(device)
            sev_labels = sev_labels.to(device)

            optimizer.zero_grad()

            cat_out, sev_out = model(images)

            loss_cat = criterion_cat(cat_out, cat_labels)
            loss_sev = criterion_sev(sev_out, sev_labels)

            loss = loss_cat + loss_sev
            loss.backward()
            optimizer.step()

            total_loss += loss.item()

        print(f"Epoch {epoch+1}/{EPOCHS}, Loss: {total_loss:.4f}")

    torch.save(model.state_dict(), MODEL_PATH)
    print("Model saved to", MODEL_PATH)


if __name__ == "__main__":
    main()
