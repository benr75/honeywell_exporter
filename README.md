# honeywell_exporter

This is a simple screen-scraping metrics exporter for Honeywell Wifi enabled thermostats.  Used to track in-house temperatures and run-frequencies of your HVAC systems.  To be used with Prometheus.

# Usage

Create a config.yml file with the following format:

```
THERM_USER: "YOUR_USER"
THERM_PASSWORD: "YOUR_PASS"
```

Start the Exporter 

```
bundle exec ruby app.rb
```

To obtain your device_id login to https://www.mytotalconnectcomfort.com/ and navigate to a thermostat. The URL will contain the device id:

```
https://www.mytotalconnectcomfort.com/portal/Device/Control/DEVICE_ID?page=1
```

You can see metrics by providing your DEVICE_ID:

```
curl localhost:9100/?device_id=DEVICE_ID # high level output
curl localhost:9100/metrics?device_id=DEVICE_ID # In prometheus format
```

Example job for Prometheus. Add a DEVICE_ID per thermostat. 

```
scrape_configs:
  - job_name: 'honeywell'
    metrics_path: /metrics
    static_configs:
      - targets:
        - DEVICE_ID
        - DEVICE_ID
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_device_id
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 127.0.0.1:9100 # This exporter's real hostname:port
```
