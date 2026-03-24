import torch.nn as nn
from torchvision.models import efficientnet_b0


class CivicClassifierEffNet(nn.Module):
    def __init__(self):
        super().__init__()
        self.backbone = efficientnet_b0(pretrained=True)
        features = self.backbone.classifier[1].in_features
        self.backbone.classifier = nn.Identity()

        self.category_head = nn.Linear(features, 7)
        self.severity_head = nn.Linear(features, 3)

    def forward(self, x):
        features = self.backbone(x)
        return self.category_head(features), self.severity_head(features)
