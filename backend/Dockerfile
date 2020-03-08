FROM python:3-slim
ENV PYTHONUNBUFFERED 1
RUN mkdir /code
COPY . /code/
WORKDIR /code/

RUN pip install -r requirements.txt

CMD [ "./entrypoint.sh" ]
