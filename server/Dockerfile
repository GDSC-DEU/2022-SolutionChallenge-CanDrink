FROM python:3.9

COPY . /app
WORKDIR /app

RUN mkdir -p tffile/

# install python package
RUN pip install -r requirements.txt

EXPOSE 8000

CMD ["python", "run.py"]