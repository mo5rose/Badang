import dash
from dash import dcc, html, Input, Output
import plotly.express as px
import pandas as pd
from data.sample_data import get_real_data
from services.forecast_service import generate_forecasts

# Load real data
data = get_real_data()

# Create Dash app
app = dash.Dash(__name__, assets_folder="assets")

# Define layout
app.layout = html.Div([
    # Header, Metrics, Chart, and Footer sections
])

# Helper function to create metric cards
def create_metric_card(title, value, icon):
    return html.Div([
        html.Img(src=icon, className="metric-icon"),
        html.H3(title, className="metric-title"),
        html.P(value, className="metric-value")
    ], className="metric")

# Callback for updating the chart
@app.callback(
    Output("meter-chart", "figure"),
    [Input("forecast-slider", "value"),
     Input("forecast-horizon", "value")]
)
def update_chart(date_range, forecast_horizon):
    filtered_data = data[(data["Timestamp"] >= pd.to_datetime(date_range[0], unit="s")) &
                         (data["Timestamp"] <= pd.to_datetime(date_range[1], unit="s"))]
    forecast_data = generate_forecasts(filtered_data, forecast_horizon)
    combined_data = pd.concat([filtered_data, forecast_data], ignore_index=True)
    
    fig = px.line(combined_data, x="Timestamp", y="Value", color="Type", title="Meter Readings")
    fig.update_traces(error_y=dict(
        type="data",
        array=filtered_data["Error_Upper"],
        arrayminus=filtered_data["Error_Lower"],
        visible=True
    ), selector={"name": "Historical"})
    return fig

# Run app
if __name__ == "__main__":
    app.run_server(debug=True)