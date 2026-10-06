# System Tuning & Firewall Guide

### 1. CPU Performance Governor & EPP
To prevent clock throttling and latency spikes on 15W U-series CPUs:

Create `/etc/tmpfiles.d/scaling-governor.conf`:
```ini
w- /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor - - - - performance
w- /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference - - - - performance
```

Apply immediately:
```bash
sudo systemd-tmpfiles --create /etc/tmpfiles.d/scaling-governor.conf
```

### 2. ZRAM Setup
*Note: CachyOS already comes configured with a 11.6GB zstd zram swap partition by default.*
To manually verify or configure `/etc/systemd/zram-generator.conf`:
```ini
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
```
Start and verify:
```bash
sudo systemctl daemon-reload
sudo systemctl restart systemd-zram-setup@zram0.service
zramctl
```

### 3. Network & Firewall
Ensure the UDP ports are open on your host firewall and forwarded on your router to this machine:

- **Factorio:** `UDP 34197`
- **Valheim:** `UDP 2456-2458`

#### Using `ufw`:
```bash
sudo ufw allow 34197/udp comment "Factorio"
sudo ufw allow 2456:2458/udp comment "Valheim"
sudo ufw reload
```

#### Using `firewalld`:
```bash
sudo firewall-cmd --permanent --add-port=34197/udp
sudo firewall-cmd --permanent --add-port=2456-2458/udp
sudo firewall-cmd --reload
```
