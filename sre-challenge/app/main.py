import os
import logging
import httpx
from fastapi import FastAPI

# 1. Configuração de Logs
logging.basicConfig(level=logging.INFO, format='{"time": "%(asctime)s", "level": "%(levelname)s", "message": "%(message)s"}')
logger = logging.getLogger(__name__)

# 2. CRIAÇÃO DO APP (Deve vir antes das rotas!)
app = FastAPI()
ENVIRONMENT = os.getenv("ENVIRONMENT", "dev")

# 3. ROTAS
@app.get("/")
async def health_check():
    return {"status": "ok", "environment": ENVIRONMENT}

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
        # Fallback caso a API externa falhe
        return {"environment": ENVIRONMENT, "ticker": [{"pair": pair.upper(), "last": "12345.00", "status": "mocked"}]}
