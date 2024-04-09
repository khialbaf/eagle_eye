//+------------------------------------------------------------------+
//|                                                    eagle_eye.mq5 |
//|                                                           mst219 |
//|                              https://github.com/mst219/eagle_eye |
//+------------------------------------------------------------------+
#property copyright "mst219"
#property link      "https://github.com/mst219/eagle_eye"
#property version   "1.00"
#property indicator_chart_window

struct struct_candle{
   datetime dt;
   double o;
   double h;
   double l;
   double c;
   char d;
};
struct_candle candle;

struct struct_resup{
   datetime time;
   double price;
   char dir;
};
struct_resup resup;

input int resupX=9;// Resistance & Support(Power)
input int queueLength=3333;// Queue Length
input ENUM_TIMEFRAMES tf=PERIOD_D1;// timeframe parent
input color cup=C'0,99,0';// candle up
input color cneutral=C'0,0,99';// candle neutral
input color cdown=C'99,0,0';// candle down

string objBN=MQLInfoString(MQL_PROGRAM_NAME)+"_",srs[];
bool start=true;
int pc=PeriodSeconds(PERIOD_CURRENT),// persiod current seconds
pp=PeriodSeconds(tf);// persiod parent seconds
datetime nc=0;

int OnInit(){
   restart();
   return(INIT_SUCCEEDED);
}
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[]){
   if(pc>=pp){
      if(start){
         MessageBox("Period Current >= Period Parent","ERROR",2);
         Print("ERROR");
         start=false;
      }
      return(rates_total);
   }
   
   int s=prev_calculated-1;
   if(prev_calculated==0){
      s=rates_total-queueLength;
      if(s<0)
         s=0;
      else while( s-1>0 && (time[s]-time[s]%pc)<=time[s-1] )
         s--;
      restart();
   }
   
   for(int i=s;i<rates_total;i++){
      //{
      char dir=-1;
      if( close[i]>close[i-1] || ( close[i]==close[i-1] && close[i]>=high[i]-(high[i]-low[i])/2 ) )
         dir=1;
      bool l=true,h=true;
      int x=i-resupX;
      for(int j=i-1;j>=x;j--){
         if(high[i]<high[j])
            h=false;
         if(low[i]>low[j])
            l=false;
      }
      if(dir==1){
         if( l && ( resup.dir!=-1 || low[i]<resup.price ) )
            newReSup(time[i],-1,low[i]);
         if( h && ( resup.dir!=1 || high[i]>resup.price ) )
            newReSup(time[i],1,high[i]);
      }else{// -1
         if( h && ( resup.dir!=1 || high[i]>resup.price ) )
            newReSup(time[i],1,high[i]);
         if( l && ( resup.dir!=-1 || low[i]<resup.price ) )
            newReSup(time[i],-1,low[i]);
      }
		//}
      //{
      datetime t=time[i]-time[i]%pp;
      if(candle.dt!=t){
         candle.dt=t;
         candle.o=open[i];
         candle.h=high[i];
         candle.l=low[i];
      }else{
         if(candle.h<high[i])
            candle.h=high[i];
         if(candle.l>low[i])
            candle.l=low[i];
      }
      candle.c=close[i];
      if(candle.o<candle.c)
         candle.d=1;
      else if(candle.o>candle.c)
         candle.d=-1;
      else candle.d=0;
      cuParent(candle);
      //}
   }
   int i=rates_total-1;
	if(nc<time[i]){
		nc=time[i];
		for(i=ArraySize(srs)-1;i>=0;i--)
			ObjectSetInteger(0,srs[i],OBJPROP_TIME,1,TimeCurrent()+pc*9);
	}
   ChartRedraw(0);
   return(rates_total);
}
void OnTimer(){}
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam){
   switch(id){
      case CHARTEVENT_OBJECT_CLICK:
      if(StringFind(sparam,objBN+"RESUP")>-1){
         if(findSRS(sparam))
            ObjectSetInteger(0,sparam,OBJPROP_TIME,1,ObjectGetInteger(0,sparam,OBJPROP_TIME,0)+pc*3);
         else{
            setSRS(sparam);
            ObjectSetInteger(0,sparam,OBJPROP_TIME,1,TimeCurrent()+pc*9);
         }
         ChartRedraw(0);
      }
      return;
   }
}
void OnDeinit(const int reason){restart();}

//
void restart(){
   ObjectsDeleteAll(0,objBN);
   ChartRedraw(0);
   start=true;
   pc=PeriodSeconds(PERIOD_CURRENT);
   candle.dt=0;
   candle.o=0;
   candle.h=0;
   candle.l=0;
   candle.c=0;
   candle.d=0;
   resup.time=0;
   resup.price=0;
   resup.dir=0;
}
void cuParent(const struct_candle &can){// create & update parent
   string n=objBN+(int)can.dt+"_BODY",nl=objBN+(int)can.dt+"_HL";
   double o=can.o,c=can.c;
   color clr=cneutral;
   if(can.d==1)
      clr=cup;
   else if(can.d==-1)
      clr=cdown;
   else{
      o+=_Point*1;
      c-=_Point*1;
   }
   
   if(ObjectFind(0,n)<0){
      ObjectCreate(0,n,OBJ_RECTANGLE,0,can.dt,o,can.dt+pp,c);
      ObjectSetInteger(0,n,OBJPROP_FILL,true);
      ObjectSetInteger(0,n,OBJPROP_BACK,true);
   }
   ObjectSetInteger(0,n,OBJPROP_COLOR,clr);
   ObjectSetDouble(0,n,OBJPROP_PRICE,0,o);
   ObjectSetDouble(0,n,OBJPROP_PRICE,1,c);
   
   if(ObjectFind(0,nl)<0){
      ObjectCreate(0,nl,OBJ_TREND,0,can.dt+(pp/2),can.h,can.dt+(pp/2),can.l);
      ObjectSetInteger(0,nl,OBJPROP_BACK,true);
      ObjectSetInteger(0,nl,OBJPROP_WIDTH,7);
   }
   ObjectSetInteger(0,nl,OBJPROP_COLOR,clr);
   ObjectSetDouble(0,nl,OBJPROP_PRICE,0,can.h);
   ObjectSetDouble(0,nl,OBJPROP_PRICE,1,can.l);
}
void newReSup(datetime time,char dir,double price){
   if( resup.dir!=0 && resup.dir!=dir )
      drawReSup("RESUP_"+resup.dir+"_"+(int)resup.time,resup.time,resup.price,resup.time+pc*3,resup.price,clrYellow);
   resup.time=time;
   resup.dir=dir;
   resup.price=price;
}
void drawReSup(string name,const datetime t1,const double p1,const datetime t2,const double p2,color clr){
   name=objBN+name;
   if(ObjectCreate(0,name,OBJ_ARROWED_LINE,0,t1,p1,t2,p2)){
      ObjectSetInteger(0,name,OBJPROP_WIDTH,3);
      ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   }else ObjectSetInteger(0,name,OBJPROP_TIME,0,t2);
}
void setSRS(string name){
	int i=ArraySize(srs);
	ArrayResize(srs,i+1);
	srs[i]=name;
}
bool findSRS(string name){
   for(int i=ArraySize(srs)-1;i>=0;i--)
      if(srs[i]==name){
         ArrayRemove(srs,i,1);
         return true;
      }
   return false;
}