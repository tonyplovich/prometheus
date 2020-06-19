{%- from 'prometheus/map.jinja' import prometheus with context %}

include:
  - prometheus

{{ prometheus.base_dir }}/file_sd.json:
  file.managed:
    - user: prometheus
    - group: prometheus
    - mode: 644
    - replace: False

{{ prometheus.base_dir }}/salt_api_sd.py:
  file.managed:
    - user: root
    - group: prometheus
    - mode: 750
    - source: salt://prometheus/files/salt_api_sd.py
    - template: jinja
    - context:
       config: {{ prometheus.salt_api_sd }}

prom_salt_sd_cron:
  cron.present:
    - name: {{ prometheus.base_dir }}/salt_api_sd.py
    - user: prometheus
    - minute: '*/2'
