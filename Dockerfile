FROM continuumio/miniconda3

WORKDIR /online_flea_market_price_negotiation

COPY requirements.txt requirements.txt 

RUN conda install --file requirements.txt

COPY . .
