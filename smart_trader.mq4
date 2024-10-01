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
// DEFINE CONSTANTS

#define SAR_STEP 0.02
#define SAR_MAXIMUM 0.2

#define ICHIMOKU1_TENKANSEN_PERIOD 9
#define ICHIMOKU1_KIJUNSEN_PERIOD 17
#define ICHIMOKU1_SENKOUSPAN_PERIOD 26

#define ICHIMOKU2_TENKANSEN_PERIOD 65
#define ICHIMOKU2_KIJUNSEN_PERIOD 129
#define ICHIMOKU2_SENKOUSPAN_PERIOD 52

// ------------------------------------------------------------------
// INDICATOR DATA

interface IIndicatorData { };

// =====================================

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

class SARIndicatorData : public IIndicatorData {
  public:
    double sarValue;
};

class PriceIndicatorData : public IIndicatorData {
  public:
    double closeValue;
    double highValue;
    double lowValue;
};

// ------------------------------------------------------------------
// INDICATOR

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
    ~Indicator() {
      cleanData();
    }

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
};

// =====================================

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

class SARIndicator : public Indicator {
  private:
    double step;
    double maximum;
    int timeframe;
  protected:
    IIndicatorData* calcValue(int shift) {
      SARIndicatorData* d = new SARIndicatorData();
      d.sarValue = iSAR(NULL, timeframe, step, maximum, shift);
      return d;
    }
  public:
    SARIndicator(double _step, double _maximum, int _timeframe = PERIOD_CURRENT) {
      this.step = _step;
      this.maximum = _maximum;
      this.timeframe = _timeframe;
    }
};

class PriceIndicator : public Indicator {
  private:
    int timeframe;
  protected:
    IIndicatorData* calcValue(int shift) {
      PriceIndicatorData* d = new PriceIndicatorData();
      d.closeValue = iClose(NULL, timeframe, shift);
      d.highValue = iHigh(NULL, timeframe, shift);
      d.lowValue = iLow(NULL, timeframe, shift);
      return d;
    }
  public:
    PriceIndicator(int _timeframe = PERIOD_CURRENT) {
      this.timeframe = _timeframe;
    }
};

// ------------------------------------------------------------------
// DATA COLLECTOR

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
// ORDER & UTILITIES

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

class BuyLimitOrder : public Order {
  public:
    BuyLimitOrder(double _lotSize, double _price, double _stopLoss, double _takeProfit) :
      Order(Symbol(), ORDER_TYPE_BUY_LIMIT, _lotSize, _price, 1, _stopLoss, _takeProfit, "Buy Limit " + Symbol(), clrGreen) { }
};

class SellLimitOrder : public Order {
  public:
    SellLimitOrder(double _lotSize, double _price, double _stopLoss, double _takeProfit) :
      Order(Symbol(), ORDER_TYPE_SELL_LIMIT, _lotSize, _price, 1, _stopLoss, _takeProfit, "Sell Limit " + Symbol(), clrRed) { }
};

class OrderUtils {
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

    static bool modify(int orderTicket, double orderOpenPrice, double stopLoss, double takeProfit) {
      bool result = OrderModify(orderTicket, orderOpenPrice, stopLoss, takeProfit, 0, clrBlue);
      if(!result) {
        Alert("OrderModify failed with error code: ", GetLastError(), ". Ticket number: ", orderTicket);
      } else {
        Alert("OrderModify successful! Ticket number: ", orderTicket);
       }
       return result;
    }

    static int countTotalOrders() {
      return OrdersTotal();
    }

    static int countBuyOrders() {
      int count = 0;
      for (int i = 0; i < countTotalOrders(); ++i) {
        if (OrderSelect(i, SELECT_BY_POS)) {
          if (OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT) ++count;
        }
      }
      return count;
    }

    static int countSellOrders() {
      int count = 0;
      for (int i = 0; i < countTotalOrders(); ++i) {
        if (OrderSelect(i, SELECT_BY_POS)) {
          if (OrderType() == OP_SELL || OrderType() == OP_SELLLIMIT) ++count;
        }
      }
      return count;
    }
};

// ------------------------------------------------------------------
// TREND DECTECTOR

class TrendDetector {
  protected:
    IndicatorDataCollector collector;
  public:
    virtual void collectData() = 0;
    virtual bool isUpTrend() = 0;
    virtual bool isDownTrend() = 0;
};

// =====================================

class BasicTrendDetector : public TrendDetector {
  private:
    PriceIndicator price;
    IchimokuIndicator icmk1;
    IchimokuIndicator icmk2;
    SARIndicator sar;
  public:
    BasicTrendDetector(int timeframe = PERIOD_CURRENT) :
      price(timeframe),
      icmk1(ICHIMOKU1_TENKANSEN_PERIOD, ICHIMOKU1_KIJUNSEN_PERIOD, ICHIMOKU1_SENKOUSPAN_PERIOD, timeframe),
      icmk2(ICHIMOKU2_TENKANSEN_PERIOD, ICHIMOKU2_KIJUNSEN_PERIOD, ICHIMOKU2_SENKOUSPAN_PERIOD, timeframe),
      sar(SAR_STEP, SAR_MAXIMUM, timeframe) {}

    void collectData() {
      collector.collectData(price, 2);
      collector.collectData(icmk1, 2);
      collector.collectData(icmk2, 2);
      collector.collectData(sar, 2);
    }

    bool isUpTrend() {
      double prevClosePrice = ((PriceIndicatorData*)collector.getData(price, 1)).closeValue;
      double currentPrice = ((PriceIndicatorData*)collector.getData(price, 0)).closeValue;

      double prevTenkanSen = ((IchimokuIndicatorData*)collector.getData(icmk2, 1)).tenkanSen;
      double currentTenkanSen = ((IchimokuIndicatorData*)collector.getData(icmk2, 0)).tenkanSen;

      double prevKijunSen = ((IchimokuIndicatorData*)collector.getData(icmk2, 1)).kijunSen;
      double currentKijunSen = ((IchimokuIndicatorData*)collector.getData(icmk2, 0)).kijunSen;

      double prevSenkouSpanA = ((IchimokuIndicatorData*)collector.getData(icmk1, 1)).senkouSpanA;
      double currentSenkouSpanA = ((IchimokuIndicatorData*)collector.getData(icmk1, 0)).senkouSpanA;

      double prevSenkouSpanB = ((IchimokuIndicatorData*)collector.getData(icmk1, 1)).senkouSpanB;
      double currentSenkouSpanB = ((IchimokuIndicatorData*)collector.getData(icmk1, 0)).senkouSpanB;

      double prevSAR = ((SARIndicatorData*)collector.getData(sar, 1)).sarValue;
      double currentSAR = ((SARIndicatorData*)collector.getData(sar, 0)).sarValue;

      bool prevClosePriceCondition = (prevClosePrice > prevSAR)
                                     && (prevClosePrice > prevTenkanSen) && (prevClosePrice > prevKijunSen)
                                     && (prevClosePrice > prevSenkouSpanA) && (prevClosePrice > prevSenkouSpanB);

      bool currentPriceCondition = (currentPrice >= currentSAR)
                                     && (currentPrice >= currentTenkanSen) && (currentPrice >= currentKijunSen)
                                     && (currentPrice >= currentSenkouSpanA) && (currentPrice >= currentSenkouSpanB);

      return prevClosePriceCondition && currentPriceCondition;
    }

    bool isDownTrend() {
      double prevClosePrice = ((PriceIndicatorData*)collector.getData(price, 1)).closeValue;
      double currentPrice = ((PriceIndicatorData*)collector.getData(price, 0)).closeValue;

      double prevTenkanSen = ((IchimokuIndicatorData*)collector.getData(icmk2, 1)).tenkanSen;
      double currentTenkanSen = ((IchimokuIndicatorData*)collector.getData(icmk2, 0)).tenkanSen;

      double prevKijunSen = ((IchimokuIndicatorData*)collector.getData(icmk2, 1)).kijunSen;
      double currentKijunSen = ((IchimokuIndicatorData*)collector.getData(icmk2, 0)).kijunSen;

      double prevSenkouSpanA = ((IchimokuIndicatorData*)collector.getData(icmk1, 1)).senkouSpanA;
      double currentSenkouSpanA = ((IchimokuIndicatorData*)collector.getData(icmk1, 0)).senkouSpanA;

      double prevSenkouSpanB = ((IchimokuIndicatorData*)collector.getData(icmk1, 1)).senkouSpanB;
      double currentSenkouSpanB = ((IchimokuIndicatorData*)collector.getData(icmk1, 0)).senkouSpanB;

      double prevSAR = ((SARIndicatorData*)collector.getData(sar, 1)).sarValue;
      double currentSAR = ((SARIndicatorData*)collector.getData(sar, 0)).sarValue;

      bool prevClosePriceCondition = (prevClosePrice < prevSAR)
                                     && (prevClosePrice < prevTenkanSen) && (prevClosePrice < prevKijunSen)
                                     && (prevClosePrice < prevSenkouSpanA) && (prevClosePrice < prevSenkouSpanB);

      bool currentPriceCondition = (currentPrice <= currentSAR)
                                     && (currentPrice <= currentTenkanSen) && (currentPrice <= currentKijunSen)
                                     && (currentPrice <= currentSenkouSpanA) && (currentPrice <= currentSenkouSpanB);

      return prevClosePriceCondition && currentPriceCondition;
    }
};

// ------------------------------------------------------------------
// SIGNAL DECTECTOR

class SignalDetector {
  protected:
    IndicatorDataCollector collector;
  public:
    virtual void collectData() = 0;
    virtual bool isBuySignal() = 0;
    virtual bool isSellSignal() = 0;
};

// =====================================

class DefaultSignalDetector : public SignalDetector {
  public:
    void collectData() {

    }

    bool isBuySignal() {
      return false;
    }

    bool isSellSignal() {
      return false;
    }
};

class USDJPYSignalDetector : public SignalDetector {
  private:
    BasicTrendDetector d1Trend;
    BasicTrendDetector h1Trend;
    BasicTrendDetector cTrend;
  public:
    USDJPYSignalDetector() : d1Trend(PERIOD_D1), h1Trend(PERIOD_H1), cTrend(PERIOD_CURRENT) {}

    void collectData() {
      d1Trend.collectData();
      h1Trend.collectData();
      cTrend.collectData();
    }

    bool isBuySignal() {
      return cTrend.isUpTrend();
    }

    bool isSellSignal() {
      return cTrend.isDownTrend();
    }
};

// ------------------------------------------------------------------
// TRADER

class SmartTrader {
  private:
    SignalDetector* detector;
  protected:
    void cleanUp() {
      if (detector != NULL) {
        delete detector;
        detector = NULL;
      }
    }
  public:
    ~SmartTrader() {
      cleanUp();
    }

    void useStrategy(string name) {
      cleanUp();

      if (name == "USDJPY") {
        detector = new USDJPYSignalDetector();
      } else {
        detector = new DefaultSignalDetector();
      }
    }

    void execute() {
      detector.collectData();
      if (detector.isBuySignal()) {
        Print(">>>>> BUY");
        //if (OrdersTotal() < 3) {
        //  OrderUtils::send(BuyOrder(0.1, Ask, Ask - 5, Ask + 5));
        //}
      } else {
        Print(">>>>> NOT BUY");
      }

      if (detector.isSellSignal()) {
        Print(">>>>> SELL");
        //if (OrdersTotal() < 3) {
        //  OrderUtils::send(SellOrder(0.1, Bid, Bid + 5, Bid - 5));
        //}
      } else {
        Print(">>>>> NOT SELL");
      }
    }
};

// ------------------------------------------------------------------
// GLOBAL VARIABLES

SmartTrader trader;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit() {
//--- create timer
  EventSetTimer(60);
  trader.useStrategy(Symbol());
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
