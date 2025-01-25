# puteri/src/dashboard.py
import dash
from dash import dcc, html
import plotly.express as px
import pandas as pd

# Load data from Kenyir
data = pd.read_csv("/path/to/kenyir/data.csv")

# Create Dash app
app = dash.Dash(__name__)

# Define layout
app.layout = html.Div([
    dcc.Graph(
        figure=px.line(data, x="timestamp", y="value", title="Meter Data Over Time")
    ),
    dcc.Graph(
        figure=px.bar(data, x="timestamp", y="prediction", title="Maintenance Predictions")
    )
])

if __name__ == "__main__":
    app.run_server(debug=True)