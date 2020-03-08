#!/bin/sh
python manage.py migrate
python manage.py add_testing_data
gunicorn project.wsgi:application --workers=2 --threads=4 --worker-class=gthread --worker-tmp-dir /dev/shm --bind 0.0.0.0:$SERVICE_PORT --access-logfile '-' --error-logfile '-'
