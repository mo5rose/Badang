# ai/core.py
import pandas as pd

class BaseAI:
    def __init__(self, data_path):
        self.data = pd.read_csv(data_path)
    
    def preprocess(self):
        # Common preprocessing steps
        self.data = self.data.dropna()
        return self.data