FROM freeipa/freeipa-server:almalinux-9

# Fix 1: Patch check_available_memory to use /proc/meminfo instead of cgroup
# Fixes cgroupv2 "Unable to determine the amount of available RAM"
# on Docker 29+ / Azure Ubuntu 24.04 (kernel 6.14, cgroupv2 only)
COPY patch-memcheck.py /tmp/patch-memcheck.py
RUN python3 /tmp/patch-memcheck.py && rm /tmp/patch-memcheck.py

# Fix 2: Disable PrivateTmp for httpd.service
# /etc/systemd/system is a symlink to /data/etc/systemd/system (populated at runtime).
# So we patch the unit file directly in /usr/lib/systemd/system/httpd.service.
# With --privileged, systemd honors PrivateTmp=true, isolating Apache's /tmp.
# This hides the gssproxy socket from mod_auth_gssapi, causing ipa-client-install
# to fail with "KerberosError: No valid Negotiate header" at the client-side setup step.
# Reference: https://github.com/freeipa/freeipa-container/issues/383
RUN sed -i 's/^PrivateTmp=true/PrivateTmp=false/' \
      /usr/lib/systemd/system/httpd.service \
      /lib/systemd/system/httpd.service 2>/dev/null || true
