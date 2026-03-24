CATEGORY_MAP = {
    "Breakage": 0,
    "Overflow": 1,
    "Clogged_Drain": 2,
    "Manhole_Missing": 3,
    "Sinkhole": 4,
    "Pipe_Leak": 5,
    "Others": 6
}

SEVERITY_MAP = {
    "Low": 0,
    "Medium": 1,
    "High": 2
}

INV_CATEGORY_MAP = {v: k for k, v in CATEGORY_MAP.items()}
INV_SEVERITY_MAP = {v: k for k, v in SEVERITY_MAP.items()}

IMAGE_SIZE = 224
BATCH_SIZE = 16
LR = 1e-4
EPOCHS = 10

DATASET_PATH = "CIVIC_DATASET"
MODEL_PATH = "civic_model.pth"
