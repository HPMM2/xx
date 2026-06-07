import random
from datetime import datetime, timedelta

def get_client_survey_results(client_id: str) -> dict:
    mock = {
        "C001": {"client_id":"C001","nps_score":3,"responses":{"overall_satisfaction":2,"support_quality":4,"product_value":2,"likelihood_to_renew":1},"open_feedback":"El producto es caro y el soporte tarda demasiado."},
        "C002": {"client_id":"C002","nps_score":8,"responses":{"overall_satisfaction":8,"support_quality":9,"product_value":7,"likelihood_to_renew":8},"open_feedback":"Muy satisfecho, solo quisiera más integraciones."},
    }
    return mock.get(client_id, {"client_id":client_id,"nps_score":random.randint(1,10),"responses":{"overall_satisfaction":random.randint(1,10),"likelihood_to_renew":random.randint(1,10)},"open_feedback":"Sin comentarios."})

def get_churn_risk_score(client_id: str) -> dict:
    mock = {
        "C001": {"client_id":"C001","risk_score":0.87,"risk_level":"HIGH","factors":[{"factor":"Disminución de uso","weight":0.35},{"factor":"NPS bajo","weight":0.30}],"days_until_renewal":18,"contract_value_usd":12000},
        "C002": {"client_id":"C002","risk_score":0.21,"risk_level":"LOW","factors":[{"factor":"Uso frecuente","weight":-0.40}],"days_until_renewal":120,"contract_value_usd":8500},
    }
    if client_id in mock:
        return mock[client_id]
    risk = round(random.uniform(0.1, 0.9), 2)
    return {"client_id":client_id,"risk_score":risk,"risk_level":"HIGH" if risk>0.65 else "MEDIUM" if risk>0.35 else "LOW","days_until_renewal":random.randint(5,180),"contract_value_usd":random.randint(2000,50000)}

TOOL_REGISTRY = {"get_client_survey_results": get_client_survey_results, "get_churn_risk_score": get_churn_risk_score}
