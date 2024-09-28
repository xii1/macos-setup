//+------------------------------------------------------------------+
//|                                                         test.mq4 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// ------------------------------------------------------------------

// ------------------------------------------------------------------

interface IIndicatorData { };

class IchimokuIndicatorData : public IIndicatorData {
  public:
    double tenkanSen;
    double kijunSen;
    double senkouSpanA;
    double senkouSpanB;
    double chikouSpan;
};

class RSIIndicatorData : public IIndicatorData {
  public:
    double rsiValue;
};

class MACDIndicatorData : public IIndicatorData {
  public:
    double macdValue;
    double signalValue;
    double macdHistValue;
};

class MAIndicatorData : public IIndicatorData {
  public:
    double maValue;
};

class BBIndicatorData : public IIndicatorData {
  public:
    double upperValue;
    double middleValue;
    double lowerValue;
};

class VolumeIndicatorData : public IIndicatorData {
  public:
    long volume;
    long avgVolume;
};
// ------------------------------------------------------------------

class Indicator {
  protected:
    IIndicatorData* data[];
    
    virtual IIndicatorData* calcValue(int shift) = 0;
    
    void cleanData() {
      for (int i = 0; i < ArraySize(data); ++i) {
        if (data[i] != NULL) {
          delete data[i];
          data[i] = NULL;
        }
      }
    }
  public:
    void collectData(int period) {
      cleanData();
      
      if (period < 0) ArrayResize(data, 1);
      else ArrayResize(data, period + 1);
      
      for (int i = 0; i < ArraySize(data); ++i) data[i] = calcValue(i);
    }
    
    IIndicatorData* getData(int shift) {
      if (shift >= 0 && shift < ArraySize(data)) return data[shift];
      else return NULL;
    }
    
    ~Indicator() {
      cleanData();
    }
};

class IchimokuIndicator : public Indicator {
  private:
    int tenkanSenPeriod;
    int kijunSenPeriod;
    int senkouSpanBPeriod;
    int timeframe;
  protected:
    IIndicatorData* calcValue(int shift) {
      IchimokuIndicatorData* d = new IchimokuIndicatorData();
      d.tenkanSen = iIchimoku(NULL, timeframe, tenkanSenPeriod, kijunSenPeriod, senkouSpanBPeriod, MODE_TENKANSEN, shift);
      d.kijunSen = iIchimoku(NULL, timeframe, tenkanSenPeriod, kijunSenPeriod, senkouSpanBPeriod, MODE_KIJUNSEN, shift);
      d.senkouSpanA = iIchimoku(NULL, timeframe, tenkanSenPeriod, kijunSenPeriod, senkouSpanBPeriod, MODE_SENKOUSPANA, shift);
      d.senkouSpanB = iIchimoku(NULL, timeframe, tenkanSenPeriod, kijunSenPeriod, senkouSpanBPeriod, MODE_SENKOUSPANB, shift);
      d.chikouSpan = iIchimoku(NULL, timeframe, tenkanSenPeriod, kijunSenPeriod, senkouSpanBPeriod, MODE_CHIKOUSPAN, shift + kijunSenPeriod);
      return d;
    }
  public:
    IchimokuIndicator(int _tenkanSenPeriod, int _kijunSenPeriod, int _senkouSpanBPeriod, int _timeframe = PERIOD_CURRENT) {
      this.tenkanSenPeriod = _tenkanSenPeriod;
      this.kijunSenPeriod = _kijunSenPeriod;
      this.senkouSpanBPeriod = _senkouSpanBPeriod;
      this.timeframe = _timeframe;
    }
};

class RSIIndicator : public Indicator {
  private:
    int period;
    ENUM_APPLIED_PRICE appliedPrice;
    int timeframe;
  protected:
    IIndicatorData* calcValue(int shift) {
      RSIIndicatorData* d = new RSIIndicatorData();
      d.rsiValue = iRSI(NULL, timeframe, period, appliedPrice, shift);
      return d;
    }
  public:
    RSIIndicator(int _period, ENUM_APPLIED_PRICE _appliedPrice, int _timeframe = PERIOD_CURRENT) {
      this.period = _period;
      this.appliedPrice = _appliedPrice;
      this.timeframe = timeframe;
    }
};

class MACDIndicator : public Indicator {
  private:
    int fastEMAPeriod;
    int slowEMAPeriod;
    int signalPeriod;   
    ENUM_APPLIED_PRICE appliedPrice;
    int timeframe;
  protected:
    IIndicatorData* calcValue(int shift) {
      MACDIndicatorData* d = new MACDIndicatorData();
      d.macdValue = iMACD(NULL, timeframe, fastEMAPeriod, slowEMAPeriod, signalPeriod, appliedPrice, MODE_MAIN, shift);
      d.signalValue = iMACD(NULL, timeframe, fastEMAPeriod, slowEMAPeriod, signalPeriod, appliedPrice, MODE_SIGNAL, shift);
      d.macdHistValue = d.macdValue - d.signalValue;
      return d;
    }
  public:
    MACDIndicator(int _fastEMAPeriod, int _slowEMAPeriod, int _signalPeriod, ENUM_APPLIED_PRICE _appliedPrice, int _timeframe = PERIOD_CURRENT) {
      this.fastEMAPeriod = _fastEMAPeriod;
      this.slowEMAPeriod = _slowEMAPeriod;
      this.signalPeriod = _signalPeriod;
      this.appliedPrice = _appliedPrice;
      this.timeframe = _timeframe;
    }
};

class MAIndicator : public Indicator {
  private:
    int maPeriod;
    int maShift;
    ENUM_MA_METHOD maMethod;
    ENUM_APPLIED_PRICE appliedPrice;
    int timeframe;
  protected:
    IIndicatorData* calcValue(int shift) {
      MAIndicatorData* d = new MAIndicatorData();
      d.maValue = iMA(NULL, timeframe, maPeriod, maShift, maMethod, appliedPrice, shift);
      return d;
    }
  public:
    MAIndicator(int _maPeriod, ENUM_MA_METHOD _maMethod, ENUM_APPLIED_PRICE _appliedPrice, int _timeframe = PERIOD_CURRENT) {
      this.maPeriod = _maPeriod;
      this.maShift = 0;
      this.maMethod = _maMethod;
      this.appliedPrice = _appliedPrice;
      this.timeframe = _timeframe;
    }
};

class BBIndicator : public Indicator {
  private:
    int period;
    double deviation;
    int bandsShift;
    ENUM_APPLIED_PRICE appliedPrice;
    int timeframe;
  protected:
    IIndicatorData* calcValue(int shift) {
      BBIndicatorData* d = new BBIndicatorData();
      d.upperValue = iBands(NULL, timeframe, period, deviation, bandsShift, appliedPrice, MODE_UPPER, shift);
      d.middleValue = iBands(NULL, timeframe, period, deviation, bandsShift, appliedPrice, MODE_MAIN, shift);
      d.lowerValue = iBands(NULL, timeframe, period, deviation, bandsShift, appliedPrice, MODE_LOWER, shift);
      return d;
    }
  public:
    BBIndicator(int _period, ENUM_APPLIED_PRICE _appliedPrice, int _timeframe = PERIOD_CURRENT) {
      this.period = _period;
      this.deviation = 2.0;
      this.bandsShift = 0;
      this.appliedPrice = _appliedPrice;
      this.timeframe = _timeframe;
    }
};

class VolumeIndicator : public Indicator {
  private:
    int period;
    int timeframe;
  protected:
    IIndicatorData* calcValue(int shift) {
      long totalVolume = 0;
      for (int i = 0; i < period; ++i) {
        totalVolume += iVolume(NULL, 0, shift + i);
      }
    
      VolumeIndicatorData* d = new VolumeIndicatorData();
      d.volume = iVolume(NULL, timeframe, shift);
      d.avgVolume = totalVolume / period;
      return d;
    }
  public:
    VolumeIndicator(int _period, int _timeframe = PERIOD_CURRENT) {
      this.period = _period;
      this.timeframe = _timeframe;
    }
};
// ------------------------------------------------------------------

class IndicatorDataCollector {
  public:
    void collectData(Indicator& indicator, int period = 0) const {
      indicator.collectData(period);
    }
    IIndicatorData* getData(Indicator& indicator, int shift = 0) const {
      return indicator.getData(shift);
    }
};
// ------------------------------------------------------------------

class Order {
  public:
    string symbol;
    ENUM_ORDER_TYPE orderType;
    double lotSize;
    double price;
    int slippage;
    double stopLoss;
    double takeProfit;
    string comment;
    color lineColor;
    
    Order(string _symbol, ENUM_ORDER_TYPE _orderType, double _lotSize, double _price, int _slippage, double _stopLoss, double _takeProfit, string _comment, color _lineColor) {
      this.symbol = _symbol;
      this.orderType = _orderType;
      this.lotSize = _lotSize;
      this.price = _price;
      this.slippage = _slippage;
      this.stopLoss = _stopLoss;
      this.takeProfit = _takeProfit;
      this.comment = _comment;
      this.lineColor = _lineColor;
    }
    
    string info() {
      return comment + " lotSize=" + (string)lotSize + ", price=" + (string)price + ", stopLoss=" + (string)stopLoss + ", takeProfit=" + (string)takeProfit + ".";
    }
};

class BuyOrder : public Order {
  public:
    BuyOrder(double _lotSize, double _price, double _stopLoss, double _takeProfit) : 
      Order(Symbol(), ORDER_TYPE_BUY, _lotSize, _price, 1, _stopLoss, _takeProfit, "Buy " + Symbol(), clrGreen) { }
};

class SellOrder : public Order {
  public:
    SellOrder(double _lotSize, double _price, double _stopLoss, double _takeProfit) : 
      Order(Symbol(), ORDER_TYPE_SELL, _lotSize, _price, 1, _stopLoss, _takeProfit, "Sell " + Symbol(), clrRed) { }
};

class OrderSender {
  public:
    static int send(Order& order) {
      int ticket = OrderSend(order.symbol, order.orderType, order.lotSize, order.price, order.slippage, order.stopLoss, order.takeProfit, order.comment, 0, 0, order.lineColor);
      
      if (ticket < 0) {
        int errorCode = GetLastError();
        Alert("OrderSend failed with error code: ", errorCode, ". Order info: ", order.info());
        
        switch (errorCode) {
          case 130: Print("Error: Invalid stop levels."); break;
          case 131: Print("Error: Invalid lot size."); break;
          case 133: Print("Error: Market is closed."); break;
          case 134: Print("Error: Not enough money."); break;
          case 146: Print("Error: Trade context is busy."); break;
          default: Print("OrderSend failed with an unknown error.");
        }
        ResetLastError();
        
        Print("MODE_LOTSIZE = ", MarketInfo(Symbol(), MODE_LOTSIZE));
        Print("MODE_MINLOT = ", MarketInfo(Symbol(), MODE_MINLOT));
        Print("MODE_LOTSTEP = ", MarketInfo(Symbol(), MODE_LOTSTEP));
        Print("MODE_MAXLOT = ", MarketInfo(Symbol(), MODE_MAXLOT));
      } else {
        Alert("OrderSend successful! Ticket number: ", ticket, ". Order info: ", order.info());
      }
      
      return ticket;
    }
};
// ------------------------------------------------------------------

interface ISignalDetector {
  public:
    bool isBuySignal();
    bool isSellSignal();
};

// ------------------------------------------------------------------

class SmartTrader {
  private:
    ISignalDetector* signalDetector;
  public:
    void setSignalDetector(ISignalDetector* _signalDetector) {
      this.signalDetector = _signalDetector;
    }
    
    void execute() {
      if (OrdersTotal() == 0) {
        OrderSender::send(BuyOrder(0.1, Ask, Ask - 10, Ask + 10));
      }
    }
};
// ------------------------------------------------------------------

SmartTrader trader;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//--- create timer
  EventSetTimer(60);
  Alert("Smart Trader has started for automatic trading ", Symbol(), " in timeframe ", Period(), " minutes.");
//---
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//--- destroy timer
  Alert("Smart Trader has stopped for automatic trading ", Symbol(), " in timeframe ", Period(), " minutes.");
  EventKillTimer();
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
  trader.execute();
}
