# puteri/app.py
import dash
from dash import dcc, html, Input, Output
import plotly.express as px
import pandas as pd
from data.sample_data import get_real_data  # Import real data function

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

# Sample data
data = pd.DataFrame({
    "Timestamp": pd.date_range(start="2023-01-01", periods=100, freq="D"),
    "Value": range(100)
})

# Create Dash app
app = dash.Dash(__name__, assets_folder="assets")

# Define layout
app.layout = html.Div([
    html.Header([
        html.Img(src="assets/logo.png", className="logo"),
        html.Nav([
            html.A("Home", href="#", className="nav-link"),
            html.A("Analytics", href="#", className="nav-link"),
            html.A("Reports", href="#", className="nav-link")
        ]),
        html.Div([
            html.Span("User Profile", className="profile-text"),
            html.Img(src="assets/profile.png", className="profile-img")
        ], className="profile")
    ], className="header"),
    html.Div([
        html.Div([
            html.H2("Overview", className="section-title"),
            html.Div([
                html.Div([
                    html.Img(src="assets/meter.png", className="metric-icon"),
                    html.H3("Total Meters", className="metric-title"),
                    html.P("100", className="metric-value")
                ], className="metric"),
                html.Div([
                    html.Img(src="assets/anomaly.png", className="metric-icon"),
                    html.H3("Anomalies", className="metric-title"),
                    html.P("5", className="metric-value")
                ], className="metric"),
                html.Div([
                    html.Img(src="assets/readings.png", className="metric-icon"),
                    html.H3("Avg. Readings", className="metric-title"),
                    html.P("50", className="metric-value")
                ], className="metric"),
                html.Div([
                    html.Img(src="assets/peak.png", className="metric-icon"),
                    html.H3("Peak Usage", className="metric-title"),
                    html.P("75", className="metric-value")
                ], className="metric")
            ], className="metrics")
        ], className="overview"),
        html.Div([
            html.H2("Meter Readings Over Time", className="section-title"),
            dcc.Graph(figure=px.line(data, x="Timestamp", y="Value", title="Meter Readings"), className="chart")
        ], className="chart-section")
    ], className="content"),
    html.Footer([
        html.A("Documentation", href="#", className="footer-link"),
        html.A("Support", href="#", className="footer-link"),
        html.A("Legal", href="#", className="footer-link")
    ], className="footer")
])

# Run app
if __name__ == "__main__":
    app.run_server(debug=True)

# Load real data
data = get_real_data()

# Create Dash app
app = dash.Dash(__name__, assets_folder="assets")

# Define layout
app.layout = html.Div([
    html.Header([
        html.Img(src="assets/logo.png", className="logo"),
        html.Nav([
            html.A("Home", href="#", className="nav-link"),
            html.A("Analytics", href="#", className="nav-link"),
            html.A("Reports", href="#", className="nav-link")
        ]),
        html.Div([
            html.Span("User Profile", className="profile-text"),
            html.Img(src="assets/profile.png", className="profile-img")
        ], className="profile")
    ], className="header"),
    html.Div([
        html.Div([
            html.H2("Overview", className="section-title"),
            html.Div([
                html.Div([
                    html.Img(src="assets/meter.png", className="metric-icon"),
                    html.H3("Total Meters", className="metric-title"),
                    html.P("100", className="metric-value")
                ], className="metric"),
                html.Div([
                    html.Img(src="assets/anomaly.png", className="metric-icon"),
                    html.H3("Anomalies", className="metric-title"),
                    html.P("5", className="metric-value")
                ], className="metric"),
                html.Div([
                    html.Img(src="assets/readings.png", className="metric-icon"),
                    html.H3("Avg. Readings", className="metric-title"),
                    html.P("50", className="metric-value")
                ], className="metric"),
                html.Div([
                    html.Img(src="assets/peak.png", className="metric-icon"),
                    html.H3("Peak Usage", className="metric-title"),
                    html.P("75", className="metric-value")
                ], className="metric")
            ], className="metrics")
        ], className="overview"),
        html.Div([
            html.H2("Meter Readings Over Time", className="section-title"),
            dcc.Graph(id="meter-chart", className="chart"),
            dcc.RangeSlider(
                id="forecast-slider",
                min=data["Timestamp"].min().timestamp(),
                max=data["Timestamp"].max().timestamp(),
                value=[data["Timestamp"].min().timestamp(), data["Timestamp"].max().timestamp()],
                marks={int(timestamp): {"label": pd.to_datetime(timestamp, unit="s").strftime("%Y-%m-%d")}
                       for timestamp in pd.date_range(start=data["Timestamp"].min(), end=data["Timestamp"].max(), periods=5).map(lambda x: x.timestamp())}
            )
        ], className="chart-section")
    ], className="content"),
    html.Footer([
        html.A("Documentation", href="#", className="footer-link"),
        html.A("Support", href="#", className="footer-link"),
        html.A("Legal", href="#", className="footer-link")
    ], className="footer")
])

# Callback for updating the chart based on the slider
@app.callback(
    Output("meter-chart", "figure"),
    Input("forecast-slider", "value")
)
def update_chart(date_range):
    filtered_data = data[(data["Timestamp"] >= pd.to_datetime(date_range[0], unit="s")) &
                         (data["Timestamp"] <= pd.to_datetime(date_range[1], unit="s"))]
    fig = px.line(filtered_data, x="Timestamp", y="Value", title="Meter Readings")
    return fig

# Run app
if __name__ == "__main__":
    app.run_server(debug=True)

# Add sample asymmetric error columns (replace these with your actual error data)
data["Error_Upper"] = data["Value"] * 0.1  # 10% upper error
data["Error_Lower"] = data["Value"] * 0.05  # 5% lower error

# Create Dash app
app = dash.Dash(__name__, assets_folder="assets")

# Define layout
app.layout = html.Div([
    html.Header([
        html.Img(src="assets/logo.png", className="logo"),
        html.Nav([
            html.A("Home", href="#", className="nav-link"),
            html.A("Analytics", href="#", className="nav-link"),
            html.A("Reports", href="#", className="nav-link")
        ]),
        html.Div([
            html.Span("User Profile", className="profile-text"),
            html.Img(src="assets/profile.png", className="profile-img")
        ], className="profile")
    ], className="header"),
    html.Div([
        html.Div([
            html.H2("Overview", className="section-title"),
            html.Div([
                html.Div([
                    html.Img(src="assets/meter.png", className="metric-icon"),
                    html.H3("Total Meters", className="metric-title"),
                    html.P("100", className="metric-value")
                ], className="metric"),
                html.Div([
                    html.Img(src="assets/anomaly.png", className="metric-icon"),
                    html.H3("Anomalies", className="metric-title"),
                    html.P("5", className="metric-value")
                ], className="metric"),
                html.Div([
                    html.Img(src="assets/readings.png", className="metric-icon"),
                    html.H3("Avg. Readings", className="metric-title"),
                    html.P("50", className="metric-value")
                ], className="metric"),
                html.Div([
                    html.Img(src="assets/peak.png", className="metric-icon"),
                    html.H3("Peak Usage", className="metric-title"),
                    html.P("75", className="metric-value")
                ], className="metric")
            ], className="metrics")
        ], className="overview"),
        html.Div([
            html.H2("Meter Readings Over Time", className="section-title"),
            dcc.Graph(id="meter-chart", className="chart"),
            dcc.RangeSlider(
                id="forecast-slider",
                min=data["Timestamp"].min().timestamp(),
                max=data["Timestamp"].max().timestamp(),
                value=[data["Timestamp"].min().timestamp(), data["Timestamp"].max().timestamp()],
                marks={int(timestamp): {"label": pd.to_datetime(timestamp, unit="s").strftime("%Y-%m-%d")}
                       for timestamp in pd.date_range(start=data["Timestamp"].min(), end=data["Timestamp"].max(), periods=5).map(lambda x: x.timestamp())}
            )
        ], className="chart-section")
    ], className="content"),
    html.Footer([
        html.A("Documentation", href="#", className="footer-link"),
        html.A("Support", href="#", className="footer-link"),
        html.A("Legal", href="#", className="footer-link")
    ], className="footer")
])

# Callback for updating the chart based on the slider
@app.callback(
    Output("meter-chart", "figure"),
    Input("forecast-slider", "value")
)
def update_chart(date_range):
    filtered_data = data[(data["Timestamp"] >= pd.to_datetime(date_range[0], unit="s")) &
                         (data["Timestamp"] <= pd.to_datetime(date_range[1], unit="s"))]
    
    # Create the chart with asymmetric error bars
    fig = px.line(filtered_data, x="Timestamp", y="Value", title="Meter Readings")
    
    # Add asymmetric error bars
    fig.update_traces(error_y=dict(
        type="data",
        array=filtered_data["Error_Upper"],  # Upper error
        arrayminus=filtered_data["Error_Lower"],  # Lower error
        visible=True
    ))
    
    return fig

# Run app
if __name__ == "__main__":
    app.run_server(debug=True)

# Create Dash app
app = dash.Dash(__name__, assets_folder="assets")

# Define layout
app.layout = html.Div([
    html.Header([
        html.Img(src="assets/logo.png", className="logo"),
        html.Nav([
            html.A("Home", href="#", className="nav-link"),
            html.A("Analytics", href="#", className="nav-link"),
            html.A("Reports", href="#", className="nav-link")
        ]),
        html.Div([
            html.Span("User Profile", className="profile-text"),
            html.Img(src="assets/profile.png", className="profile-img")
        ], className="profile")
    ], className="header"),
    html.Div([
        html.Div([
            html.H2("Overview", className="section-title"),
            html.Div([
                html.Div([
                    html.Img(src="assets/meter.png", className="metric-icon"),
                    html.H3("Total Meters", className="metric-title"),
                    html.P("100", className="metric-value")
                ], className="metric"),
                html.Div([
                    html.Img(src="assets/anomaly.png", className="metric-icon"),
                    html.H3("Anomalies", className="metric-title"),
                    html.P("5", className="metric-value")
                ], className="metric"),
                html.Div([
                    html.Img(src="assets/readings.png", className="metric-icon"),
                    html.H3("Avg. Readings", className="metric-title"),
                    html.P("50", className="metric-value")
                ], className="metric"),
                html.Div([
                    html.Img(src="assets/peak.png", className="metric-icon"),
                    html.H3("Peak Usage", className="metric-title"),
                    html.P("75", className="metric-value")
                ], className="metric")
            ], className="metrics")
        ], className="overview"),
        html.Div([
            html.H2("Meter Readings Over Time", className="section-title"),
            dcc.Graph(id="meter-chart", className="chart"),
            dcc.RangeSlider(
                id="forecast-slider",
                min=data["Timestamp"].min().timestamp(),
                max=data["Timestamp"].max().timestamp(),
                value=[data["Timestamp"].min().timestamp(), data["Timestamp"].max().timestamp()],
                marks={int(timestamp): {"label": pd.to_datetime(timestamp, unit="s").strftime("%Y-%m-%d")}
                       for timestamp in pd.date_range(start=data["Timestamp"].min(), end=data["Timestamp"].max(), periods=5).map(lambda x: x.timestamp())}
            )
        ], className="chart-section")
    ], className="content"),
    html.Footer([
        html.A("Documentation", href="#", className="footer-link"),
        html.A("Support", href="#", className="footer-link"),
        html.A("Legal", href="#", className="footer-link")
    ], className="footer")
])

# Callback for updating the chart based on the slider
@app.callback(
    Output("meter-chart", "figure"),
    Input("forecast-slider", "value")
)
def update_chart(date_range):
    filtered_data = data[(data["Timestamp"] >= pd.to_datetime(date_range[0], unit="s")) &
                         (data["Timestamp"] <= pd.to_datetime(date_range[1], unit="s"))]
    
    # Create the chart with asymmetric error bars
    fig = px.line(filtered_data, x="Timestamp", y="Value", title="Meter Readings")
    
    # Add asymmetric error bars
    fig.update_traces(error_y=dict(
        type="data",
        array=filtered_data["Error_Upper"],  # Upper error
        arrayminus=filtered_data["Error_Lower"],  # Lower error
        visible=True
    ))
    
    return fig

# Run app
if __name__ == "__main__":
    app.run_server(debug=True)

# Load real data
data = get_real_data()

# Create Dash app
app = dash.Dash(__name__, assets_folder="assets")

# Define layout
app.layout = html.Div([
    html.Header([
        html.Img(src="assets/logo.png", className="logo"),
        html.Nav([
            html.A("Home", href="#", className="nav-link"),
            html.A("Analytics", href="#", className="nav-link"),
            html.A("Reports", href="#", className="nav-link")
        ]),
        html.Div([
            html.Span("User Profile", className="profile-text"),
            html.Img(src="assets/profile.png", className="profile-img")
        ], className="profile")
    ], className="header"),
    html.Div([
        html.Div([
            html.H2("Overview", className="section-title"),
            html.Div([
                html.Div([
                    html.Img(src="assets/meter.png", className="metric-icon"),
                    html.H3("Total Meters", className="metric-title"),
                    html.P("100", className="metric-value")
                ], className="metric"),
                html.Div([
                    html.Img(src="assets/anomaly.png", className="metric-icon"),
                    html.H3("Anomalies", className="metric-title"),
                    html.P("5", className="metric-value")
                ], className="metric"),
                html.Div([
                    html.Img(src="assets/readings.png", className="metric-icon"),
                    html.H3("Avg. Readings", className="metric-title"),
                    html.P("50", className="metric-value")
                ], className="metric"),
                html.Div([
                    html.Img(src="assets/peak.png", className="metric-icon"),
                    html.H3("Peak Usage", className="metric-title"),
                    html.P("75", className="metric-value")
                ], className="metric")
            ], className="metrics")
        ], className="overview"),
        html.Div([
            html.H2("Meter Readings Over Time", className="section-title"),
            dcc.Graph(id="meter-chart", className="chart"),
            dcc.RangeSlider(
                id="forecast-slider",
                min=data["Timestamp"].min().timestamp(),
                max=data["Timestamp"].max().timestamp(),
                value=[data["Timestamp"].min().timestamp(), data["Timestamp"].max().timestamp()],
                marks={int(timestamp): {"label": pd.to_datetime(timestamp, unit="s").strftime("%Y-%m-%d")}
                       for timestamp in pd.date_range(start=data["Timestamp"].min(), end=data["Timestamp"].max(), periods=5).map(lambda x: x.timestamp())}
            )
        ], className="chart-section")
    ], className="content"),
    html.Footer([
        html.A("Documentation", href="#", className="footer-link"),
        html.A("Support", href="#", className="footer-link"),
        html.A("Legal", href="#", className="footer-link")
    ], className="footer")
])

# Callback for updating the chart based on the slider
@app.callback(
    Output("meter-chart", "figure"),
    Input("forecast-slider", "value")
)
def update_chart(date_range):
    filtered_data = data[(data["Timestamp"] >= pd.to_datetime(date_range[0], unit="s")) &
                         (data["Timestamp"] <= pd.to_datetime(date_range[1], unit="s"))]
    
    # Create the chart
    fig = px.line(filtered_data, x="Timestamp", y="Value", color="Type", title="Meter Readings (Historical & Forecast)")
    
    # Add error bars for historical data
    historical_data = filtered_data[filtered_data["Type"] == "Historical"]
    fig.update_traces(error_y=dict(
        type="data",
        array=historical_data["Error_Upper"],  # Upper error
        arrayminus=historical_data["Error_Lower"],  # Lower error
        visible=True
    ), selector={"name": "Historical"})
    
    # Add confidence intervals for forecasted data
    forecast_data = filtered_data[filtered_data["Type"] == "Forecast"]
    fig.add_trace(px.line(forecast_data, x="Timestamp", y="Value", line_dash="Type").data[0])
    fig.add_trace(px.line(forecast_data, x="Timestamp", y="Error_Lower", line_dash="Type").data[0])
    fig.add_trace(px.line(forecast_data, x="Timestamp", y="Error_Upper", line_dash="Type").data[0])
    
    return fig

# Run app
if __name__ == "__main__":
    app.run_server(debug=True)

# Create Dash app
app = dash.Dash(__name__, assets_folder="assets")

# Define layout
app.layout = html.Div([
    html.Header([
        html.Img(src="assets/logo.png", className="logo"),
        html.Nav([
            html.A("Home", href="#", className="nav-link"),
            html.A("Analytics", href="#", className="nav-link"),
            html.A("Reports", href="#", className="nav-link")
        ]),
        html.Div([
            html.Span("User Profile", className="profile-text"),
            html.Img(src="assets/profile.png", className="profile-img")
        ], className="profile")
    ], className="header"),
    html.Div([
        html.Div([
            html.H2("Overview", className="section-title"),
            html.Div([
                html.Div([
                    html.Img(src="assets/meter.png", className="metric-icon"),
                    html.H3("Total Meters", className="metric-title"),
                    html.P("100", className="metric-value")
                ], className="metric"),
                html.Div([
                    html.Img(src="assets/anomaly.png", className="metric-icon"),
                    html.H3("Anomalies", className="metric-title"),
                    html.P("5", className="metric-value")
                ], className="metric"),
                html.Div([
                    html.Img(src="assets/readings.png", className="metric-icon"),
                    html.H3("Avg. Readings", className="metric-title"),
                    html.P("50", className="metric-value")
                ], className="metric"),
                html.Div([
                    html.Img(src="assets/peak.png", className="metric-icon"),
                    html.H3("Peak Usage", className="metric-title"),
                    html.P("75", className="metric-value")
                ], className="metric")
            ], className="metrics")
        ], className="overview"),
        html.Div([
            html.H2("Meter Readings Over Time", className="section-title"),
            dcc.Graph(id="meter-chart", className="chart"),
            html.Div([
                html.Label("Forecasting Horizon (days):"),
                dcc.Input(id="forecast-horizon", type="number", value=30, min=1, max=365, step=1)
            ], className="forecast-control"),
            dcc.RangeSlider(
                id="forecast-slider",
                min=data["Timestamp"].min().timestamp(),
                max=data["Timestamp"].max().timestamp(),
                value=[data["Timestamp"].min().timestamp(), data["Timestamp"].max().timestamp()],
                marks={int(timestamp): {"label": pd.to_datetime(timestamp, unit="s").strftime("%Y-%m-%d")}
                       for timestamp in pd.date_range(start=data["Timestamp"].min(), end=data["Timestamp"].max(), periods=5).map(lambda x: x.timestamp())}
            )
        ], className="chart-section")
    ], className="content"),
    html.Footer([
        html.A("Documentation", href="#", className="footer-link"),
        html.A("Support", href="#", className="footer-link"),
        html.A("Legal", href="#", className="footer-link")
    ], className="footer")
])

# Callback for updating the chart based on the slider and forecasting horizon
@app.callback(
    Output("meter-chart", "figure"),
    [Input("forecast-slider", "value"),
     Input("forecast-horizon", "value")]
)
def update_chart(date_range, forecast_horizon):
    # Get historical data within the selected range
    historical_data = data[(data["Timestamp"] >= pd.to_datetime(date_range[0], unit="s")) &
                           (data["Timestamp"] <= pd.to_datetime(date_range[1], unit="s"))]
    
    # Generate forecasts for the selected horizon
    forecast_data = generate_forecasts(historical_data, forecast_horizon)
    
    # Combine historical and forecasted data
    combined_data = pd.concat([historical_data, forecast_data], ignore_index=True)
    
    # Create the chart
    fig = px.line(combined_data, x="Timestamp", y="Value", color="Type", title="Meter Readings (Historical & Forecast)")
    
    # Add error bars for historical data
    historical_data = combined_data[combined_data["Type"] == "Historical"]
    fig.update_traces(error_y=dict(
        type="data",
        array=historical_data["Error_Upper"],  # Upper error
        arrayminus=historical_data["Error_Lower"],  # Lower error
        visible=True
    ), selector={"name": "Historical"})
    
    # Add confidence intervals for forecasted data
    forecast_data = combined_data[combined_data["Type"] == "Forecast"]
    fig.add_trace(px.line(forecast_data, x="Timestamp", y="Value", line_dash="Type").data[0])
    fig.add_trace(px.line(forecast_data, x="Timestamp", y="Error_Lower", line_dash="Type").data[0])
    fig.add_trace(px.line(forecast_data, x="Timestamp", y="Error_Upper", line_dash="Type").data[0])
    
    return fig

def generate_forecasts(data, horizon):
    """
    Generate forecasts using Facebook Prophet.
    """
    # Prepare data for Prophet
    prophet_data = data[["Timestamp", "Value"]]
    prophet_data.columns = ["ds", "y"]
    
    # Train Prophet model
    model = Prophet()
    model.fit(prophet_data)
    
    # Generate future predictions
    future = model.make_future_dataframe(periods=horizon)  # Forecast for the selected horizon
    forecast = model.predict(future)
    
    # Extract relevant columns
    forecast_data = forecast[["ds", "yhat", "yhat_lower", "yhat_upper"]]
    forecast_data.columns = ["Timestamp", "Value", "Error_Lower", "Error_Upper"]
    forecast_data["Type"] = "Forecast"
    
    return forecast_data

# Run app
if __name__ == "__main__":
    app.run_server(debug=True)