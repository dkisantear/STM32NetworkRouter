# Heartbeat Interval Options

## Recommended: 30 seconds ⭐

**Quota Impact**: 86,400 requests/month (safe, well under 125k limit)  
**Update Speed**: Status updates within 30-38 seconds  
**Best Balance**: Fast updates + quota efficient

---

## Other Options

### 20 seconds (Very Fast)
**Quota Impact**: 129,600 requests/month (close to 125k limit, risky)  
**Update Speed**: Status updates within 20-28 seconds  
**Risk**: May exceed quota if running 24/7

### 45 seconds (Moderate)
**Quota Impact**: 57,600 requests/month (very safe)  
**Update Speed**: Status updates within 45-53 seconds  
**Good for**: Very quota-conscious setups

### 60 seconds (Current - Safe)
**Quota Impact**: 43,200 requests/month (very safe)  
**Update Speed**: Status updates within 60-68 seconds  
**Good for**: Maximum quota efficiency

### ❌ 15 seconds (NOT Recommended)
**Quota Impact**: 172,800 requests/month ❌ **EXCEEDS 125k limit!**  
**Would cause**: Quota exceeded errors

---

## How to Change It

### Option 1: Quick Update (30 seconds)
Run this on your Pi:
```bash
cd ~/gateway-heartbeat
sudo systemctl stop gateway-heartbeat.service
sed -i 's/HEARTBEAT_INTERVAL = 60/HEARTBEAT_INTERVAL = 30/' pi_heartbeat_automated.py
sudo systemctl start gateway-heartbeat.service
```

### Option 2: Manual Edit
```bash
nano ~/gateway-heartbeat/pi_heartbeat_automated.py
# Find: HEARTBEAT_INTERVAL = 60
# Change to: HEARTBEAT_INTERVAL = 30 (or 20, or 45)
# Save and restart:
sudo systemctl restart gateway-heartbeat.service
```

---

## Recommendation

**Use 30 seconds** - perfect balance:
- ✅ Fast updates (30-38s)
- ✅ Safe quota usage (86k/month)
- ✅ Better user experience than 60s
- ✅ Still efficient

Want me to create an update script for 30 seconds?

