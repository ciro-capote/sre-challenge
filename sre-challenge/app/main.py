from fastapi import FastAPI
import httpx
import os
import logging

logging.basicConfig(level=logging.INFO, format='{"time": "%(asctime)s", "level": "%(levelname)s", "message": "%(message)s"}')
logger = logging.getLogger(__name__)

app = FastAPI()
ENVIRONMENT = os.getenv("ENVIRONMENT", "dev")

@app.get("/{pair}")
async def get_ticker(pair: str):
    logger.info(f"Recebida requisicao para {pair} no ambiente {ENVIRONMENT}")
    formatted_pair = f"{pair}-BRL".upper()
    url = f"https://api.mercadobitcoin.net/api/v4/tickers?symbols={formatted_pair}"
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(url)
            response.raise_for_status()
            return {"environment": ENVIRONMENT, "ticker": response.json()}
    except Exception as e:
        logger.error(f"Erro ao buscar API: {str(e)}")
        return {"environment": ENVIRONMENT, "ticker": [{"pair": pair.upper(), "last": "12345.00", "status": "mocked"}]}
