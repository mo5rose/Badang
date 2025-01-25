# ai/anomaly_detection.py
from sklearn.ensemble import IsolationForest
from .core import BaseAI

class AnomalyDetection(BaseAI):
    def train(self):
        X = self.preprocess()
        self.model = IsolationForest()
        self.model.fit(X)
    
    def detect(self, data):
        return self.model.predict([data])[0] == -1