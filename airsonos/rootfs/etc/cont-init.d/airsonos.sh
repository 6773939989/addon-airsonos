#!/command/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: AirSonos
# Checks latency settings before starting the AirSonos server
# ==============================================================================
declare latency

# Create a configuration file, if it does not exist yet
if ! bashio::fs.file_exists '/config/airsonos.xml'; then
    cp /etc/airsonos.xml /config/airsonos.xml
fi

# Warn if latency is below 500ms
latency=$(bashio::config 'latency_rtp')
if [[ "${latency}" -lt 500 && "${latency}" -ne 0 ]]; then
    bashio::log.warning \
        'Setting the RTP latency of AirPlay audio below 500ms is not recommended!'
fi
