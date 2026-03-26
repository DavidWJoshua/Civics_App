import os
from torch.utils.data import Dataset
from PIL import Image
from config import CATEGORY_MAP, SEVERITY_MAP


class CivicDataset(Dataset):
    def __init__(self, root_dir, transform=None):
        self.samples = []
        self.transform = transform

        for category in os.listdir(root_dir):
            cat_path = os.path.join(root_dir, category)
            if not os.path.isdir(cat_path):
                continue

            if category == "Others":
                for img in os.listdir(os.path.join(cat_path, "General")):
                    self.samples.append((
                        os.path.join(cat_path, "General", img),
                        CATEGORY_MAP["Others"],
                        -1
                    ))
            else:
                for severity in os.listdir(cat_path):
                    sev_path = os.path.join(cat_path, severity)
                    for img in os.listdir(sev_path):
                        self.samples.append((
                            os.path.join(sev_path, img),
                            CATEGORY_MAP[category],
                            SEVERITY_MAP[severity]
                        ))

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        img_path, cat_label, sev_label = self.samples[idx]
        image = Image.open(img_path).convert("RGB")

        if self.transform:
            image = self.transform(image)

        return image, cat_label, sev_label
