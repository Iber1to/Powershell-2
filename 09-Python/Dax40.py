import yfinance as yf
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Función para calcular el RSI
def calculate_RSI(series, period=14):
    delta = series.diff()
    gain = delta.clip(lower=0)
    loss = -delta.clip(upper=0)
    avg_gain = gain.rolling(window=period).mean()
    avg_loss = loss.rolling(window=period).mean()
    RS = avg_gain / avg_loss
    RSI = 100 - (100 / (1 + RS))
    return RSI

# Descargar datos del DAX en intervalos de 5 minutos durante 60 días
ticker = "^GDAXI"
data = yf.download(ticker, interval="5m", period="60d")

if data.empty:
    raise Exception("No se pudieron descargar los datos del DAX. Verifica el ticker o la conexión.")

# Calcular indicadores técnicos
data['EMA9'] = data['Close'].ewm(span=9, adjust=False).mean()
data['EMA21'] = data['Close'].ewm(span=21, adjust=False).mean()
data['RSI'] = calculate_RSI(data['Close'], period=14)

# Calcular Bollinger Bands (20 períodos, desviación estándar de 2)
data['MA20'] = data['Close'].rolling(window=20).mean()
data['STD20'] = data['Close'].rolling(window=20).std()
data['Upper'] = data['MA20'] + 2 * data['STD20']
data['Lower'] = data['MA20'] - 2 * data['STD20']

# Inicializar variables para el backtesting
position = None    # 'long' o 'short'
entry_price = 0
stop_loss = 0
take_profit = 0
trades = []

# Parámetros de gestión de riesgo
risk_pct = 0.005   # 0.5% de riesgo
rr_ratio = 2       # Relación riesgo:beneficio de 1:2

# Iterar sobre el DataFrame para simular operaciones
for i in range(1, len(data)):
    current = data.iloc[i]
    previous = data.iloc[i-1]
    
    # Señales de cruce de medias
    long_signal = (previous['EMA9'] < previous['EMA21']) and (current['EMA9'] >= current['EMA21'])
    short_signal = (previous['EMA9'] > previous['EMA21']) and (current['EMA9'] <= current['EMA21'])
    
    # Condiciones adicionales con RSI
    if position is None:
        if long_signal and current['RSI'] < 70:
            # Abrir posición long
            entry_price = current['Open']
            stop_loss = entry_price * (1 - risk_pct)
            take_profit = entry_price * (1 + risk_pct * rr_ratio)
            position = 'long'
            trade = {
                'entry_time': data.index[i],
                'position': position,
                'entry_price': entry_price,
                'stop_loss': stop_loss,
                'take_profit': take_profit,
                'exit_time': None,
                'exit_price': None,
                'pnl': None
            }
            trades.append(trade)
        elif short_signal and current['RSI'] > 30:
            # Abrir posición short
            entry_price = current['Open']
            stop_loss = entry_price * (1 + risk_pct)
            take_profit = entry_price * (1 - risk_pct * rr_ratio)
            position = 'short'
            trade = {
                'entry_time': data.index[i],
                'position': position,
                'entry_price': entry_price,
                'stop_loss': stop_loss,
                'take_profit': take_profit,
                'exit_time': None,
                'exit_price': None,
                'pnl': None
            }
            trades.append(trade)
    else:
        # Si hay posición abierta, revisar condiciones de salida
        current_trade = trades[-1]
        exit_trade = False
        exit_price = None
        exit_time = data.index[i]
        
        if position == 'long':
            if current['Low'] <= stop_loss:
                exit_trade = True
                exit_price = stop_loss
            elif current['High'] >= take_profit:
                exit_trade = True
                exit_price = take_profit
            elif short_signal:
                exit_trade = True
                exit_price = current['Close']
        elif position == 'short':
            if current['High'] >= stop_loss:
                exit_trade = True
                exit_price = stop_loss
            elif current['Low'] <= take_profit:
                exit_trade = True
                exit_price = take_profit
            elif long_signal:
                exit_trade = True
                exit_price = current['Close']
        
        if exit_trade:
            if position == 'long':
                pnl = (exit_price - entry_price) / entry_price
            else:
                pnl = (entry_price - exit_price) / entry_price
            current_trade['exit_time'] = exit_time
            current_trade['exit_price'] = exit_price
            current_trade['pnl'] = pnl
            position = None

# Convertir operaciones a DataFrame y filtrar las cerradas
trades_df = pd.DataFrame(trades)
trades_df = trades_df.dropna(subset=['exit_time'])

# Calcular métricas de desempeño
total_trades = len(trades_df)
winning_trades = trades_df[trades_df['pnl'] > 0]
losing_trades = trades_df[trades_df['pnl'] <= 0]
win_rate = len(winning_trades) / total_trades if total_trades > 0 else 0
average_pnl = trades_df['pnl'].mean() if total_trades > 0 else 0
total_return = trades_df['pnl'].sum()

print("Resumen del Backtesting:")
print(f"Total de operaciones: {total_trades}")
print(f"Operaciones ganadoras: {len(winning_trades)}")
print(f"Operaciones perdedoras: {len(losing_trades)}")
print(f"Win rate: {win_rate*100:.2f}%")
print(f"Beneficio/Pérdida promedio por operación: {average_pnl*100:.2f}%")
print(f"Retorno total acumulado: {total_return*100:.2f}%")

# Graficar la evolución del equity suponiendo capital inicial de 100 unidades
initial_capital = 100
capital = initial_capital
equity_curve = [capital]
for pnl in trades_df['pnl']:
    capital *= (1 + pnl)
    equity_curve.append(capital)

plt.figure(figsize=(10,5))
plt.plot(equity_curve, marker='o')
plt.title("Evolución del Equity en el Backtesting")
plt.xlabel("Número de operaciones")
plt.ylabel("Capital")
plt.grid(True)
plt.show()
