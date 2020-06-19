{%- from 'prometheus/map.jinja' import prometheus with context %}

{{ prometheus.base_dir }}/textfiles/:
  file.directory:
    - user: root
    - group: root
    - dir_mode: 755

{{ prometheus.base_dir }}/textfile_collector_scripts/:
  file.directory:
    - user: root
    - group: root
    - dir_mode: 755
