<!-- omit in toc -->
# 2022-SolutionChallenge-CanDrink

This project is **CanDrink**, a canned drink recognition service for the visually impaired.

## Summary

Of the many canned drinks, there are only two types of drinks that can be classified in braille: 'just drink' and 'soda'. This is what canned drinks look like from a blind person's point of view. So we created a service that helps visually impaired people choose their favorite drinks.


**[YouTube Link](https://www.youtube.com/embed/zg14ulTd5mM)**

<br><br>

<!-- omit in toc -->
# [ANNOUNCE] Congrats!! This project has been shortlisted to the global TOP 50!

![image](https://user-images.githubusercontent.com/20203944/170526199-496c7776-de75-4b18-bf48-9ff3611289b4.png)

<br><br>

<!-- omit in toc -->
# Table of Contents

- [CanDrink Server](#candrink-server)
  - [Getting Started](#getting-started)
    - [Installation](#installation)
    - [Run](#run)
  - [Directory](#directory)
  - [LICENSE](#license)
- [CanDrink Client](#candrink-client)
  - [Getting Started](#getting-started-1)
    - [Prerequisite](#prerequisite)
    - [Installation](#installation-1)
    - [Run](#run-1)
  - [LICENSE](#license-1)
- [Crawler](#crawler)
  - [Getting Started](#getting-started-2)
    - [Installation](#installation-2)
    - [Run](#run-2)
  - [LICENSE](#license-2)

<br><br>

# CanDrink Server

![https://www.docker.com/](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=Docker&logoColor=white)
![https://fastapi.tiangolo.com/ko/](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=FastAPI&logoColor=white)

> CanDrink Server

## Getting Started  

### Installation

```sh
git clone https://github.com/GDSC-DEU/2022-SolutionChallenge-CanDrink
cd server
```

### Run

```sh
docker-compose up
```

## Directory

```sh
app
├─ routes
│  ├─ views.py
├─ tffile
│  ├─ models #model files
├─ main.py
├─ run.py
```

## LICENSE

[MIT License](./LICENSE)

<br><br>

# CanDrink Client
![https://flutter.dev/](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=Flutter&logoColor=white)
![https://www.tensorflow.org/](https://img.shields.io/badge/TensorFlow-FF6F00?style=for-the-badge&logo=TensorFlow&logoColor=white)
<!-- ML Kit -->

## Getting Started

### Prerequisite

You need flutter SDK to run this project.

See **[Flutter Installation](https://docs.flutter.dev/get-started/install)**.

### Installation

```
git clone https://github.com/GDSC-DEU/2022-SolutionChallenge-CanDrink
cd client
code .
```
And you can see VSCode with this project.

### Run

Press `F5` to run on VSCode.

## LICENSE

[MIT License](./LICENSE)

<br><br>

# Crawler

![https://www.selenium.dev/](https://img.shields.io/badge/Selenium-43B02A?style=for-the-badge&logo=Selenium&logoColor=white)
![https://www.python.org/](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=Python&logoColor=white)

## Getting Started  

### Installation

```
git clone https://github.com/GDSC-DEU/2022-SolutionChallenge-CanDrink

pip install -r requirements.txt

echo "KEYWORD=[serch keyword]" >> .env
echo "KEY=[save key]" >> .env
echo "NAME=[forlder name]" >> .env
```

### Run

```
python crawler.py
```

## LICENSE

[MIT License](./LICENSE)