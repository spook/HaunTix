# Test data for the hauntix database
use hauntix;

insert into config set
  cfgName = "htx.version",
  cfgValue = "0.2";

insert into config set
  cfgName = "tax.rate",
  cfgValue = "0.039";

insert into products set
  prdName = "Regular Admission",
  prdCost = 1500,
  prdClass = "REG",
  prdIsTicket = true,
  prdWebVisible = true,
  prdScreenPosition = 2;

insert into products set
  prdName = "VIP Admission",
  prdCost = 2000,
  prdClass = "VIP",
  prdIsTicket = true,
  prdWebVisible = true,
  prdScreenPosition = 5;

insert into products set
  prdName = "Museum Admission",
  prdCost = 500,
  prdClass = "MSM",
  prdIsTicket = true,
  prdWebVisible = true,
  prdScreenPosition = 8;

insert into products set
  prdName = "VIP Upgrade",
  prdCost = 500,
  prdClass = "VIP",
  prdIsTicket = true,
  prdScreenPosition = 11;

insert into products set
  prdName = "Regular Timed",
  prdCost = 1300,
  prdClass = "REG",
  prdIsTicket = true,
  prdIsTimed = true,
  prdWebVisible = true,
  prdScreenPosition = 17;

insert into products set
  prdName = "VIP Timed",
  prdCost = 1800,
  prdClass = "VIP",
  prdIsTicket = true,
  prdIsTimed = true,
  prdWebVisible = true,
  prdScreenPosition = 20;


insert into products set
  prdName = "Early Rehearsal",
  prdCost = 1500,
  prdClass = "REG",
  prdIsTicket = true,
  prdIsTimed = false,
  prdWebVisible = true,
  prdScreenPosition = 21;

insert into products set
  prdName = "Late Rehearsal",
  prdCost = 1500,
  prdClass = "REG",
  prdIsTicket = true,
  prdIsTimed = false,
  prdWebVisible = true,
  prdScreenPosition = 22;

insert into products set
  prdName = "Rehearsal Timed VIP",
  prdCost = 2000,
  prdClass = "VIP",
  prdIsTicket = true,
  prdIsTimed = true,
  prdWebVisible = true,
  prdScreenPosition = 24;



insert into products set
  prdName = "Beanie",
  prdCost = 1000,
  prdIsTaxable = true,
  prdClass = "merchandise",
  prdScreenPosition = 0;

insert into products set
  prdName = "T-Shirt Basic",
  prdCost = 1000,
  prdIsTaxable = true,
  prdClass = "merchandise",
  prdScreenPosition = 3;

insert into products set
  prdName = "T-Shirt Premium",
  prdCost = 1500,
  prdIsTaxable = true,
  prdClass = "merchandise",
  prdScreenPosition = 4;

insert into products set
  prdName = "Haunt Shirt",
  prdCost = 1500,
  prdIsTaxable = true,
  prdClass = "merchandise",
  prdScreenPosition = 6;

insert into products set
  prdName = "Hoodie",
  prdCost = 3000,
  prdIsTaxable = true,
  prdClass = "merchandise",
  prdScreenPosition = 7;

#insert into upgrades set
#  upgName = "VIP Upgrade",
#  upgFromPrdId = 1,
#  upgToPrdId = 2,
#  upgScreenPosition = 18;    # no upgCost, should be null which means to compute automatically

#insert into discounts set
#  dscName = "Military Discount",
#  dscMethod = "FixedAmount",
#  dscAmount = 300,
#  dscScreenPosition = 2;

#insert into discounts set
#  dscName = "Senior Discount",
#  dscMethod = "FixedAmount",
#  dscAmount = 200,
#  dscScreenPosition = 5;


# Timed-ticket shows
insert into shows set shoTime = "2011-10-01 19:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-01 19:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-01 20:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-01 20:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-01 20:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-01 20:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-01 21:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-01 21:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-01 21:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-01 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-01 22:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-01 22:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-01 22:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-01 22:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-01 23:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-01 23:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-01 23:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-01 23:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;

insert into shows set shoTime = "2011-10-02 19:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-02 19:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-02 20:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-02 20:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-02 20:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-02 20:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-02 21:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-02 21:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-02 21:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-02 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-02 22:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-02 22:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-02 22:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-02 22:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-02 23:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-02 23:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-02 23:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-02 23:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;

insert into shows set shoTime = "2011-10-03 19:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1300;
insert into shows set shoTime = "2011-10-03 19:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-03 20:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1300;
insert into shows set shoTime = "2011-10-03 20:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-03 20:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1300;
insert into shows set shoTime = "2011-10-03 20:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-03 21:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1300;
insert into shows set shoTime = "2011-10-03 21:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-03 21:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1300;
insert into shows set shoTime = "2011-10-03 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;

insert into shows set shoTime = "2011-10-08 19:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-08 19:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-08 20:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-08 20:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-08 20:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-08 20:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-08 21:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-08 21:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-08 21:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-08 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-08 22:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-08 22:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-08 22:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-08 22:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-08 23:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-08 23:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-08 23:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-08 23:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;

insert into shows set shoTime = "2011-10-09 19:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-09 19:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-09 20:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-09 20:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-09 20:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-09 20:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-09 21:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-09 21:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-09 21:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-09 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-09 22:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-09 22:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-09 22:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-09 22:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-09 23:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-09 23:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;
insert into shows set shoTime = "2011-10-09 23:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1500;
insert into shows set shoTime = "2011-10-09 23:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 2000;

insert into shows set shoTime = "2011-10-10 19:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1300;
insert into shows set shoTime = "2011-10-10 19:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-10 20:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1300;
insert into shows set shoTime = "2011-10-10 20:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-10 20:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1300;
insert into shows set shoTime = "2011-10-10 20:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-10 21:00:00", shoClass = "REG", shoIsTimed = true, shoCost = 1300;
insert into shows set shoTime = "2011-10-10 21:00:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-10 21:30:00", shoClass = "REG", shoIsTimed = true, shoCost = 1300;
insert into shows set shoTime = "2011-10-10 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;

insert into shows set shoTime = "2011-10-15 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-16 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-17 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-22 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-23 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-24 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-25 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-26 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-27 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-28 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-29 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-30 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;
insert into shows set shoTime = "2011-10-31 21:30:00", shoClass = "VIP", shoIsTimed = true, shoCost = 1800;


# Special shows with different name
insert into shows set shoTime = "2012-09-17 20:00:00", shoClass = "REG", shoCost = 2750, shoName="Early Rehearsal";
insert into shows set shoTime = "2012-07-04 20:00:00", shoClass = "VIP", shoCost = 4950, shoName="Early Rehearsal", shoIsTimed=true;
insert into shows set shoTime = "2012-09-17 20:00:00", shoClass = "REG", shoCost = 2750, shoName="Late Rehearsal";
insert into shows set shoTime = "2012-07-04 20:00:00", shoClass = "VIP", shoCost = 4950, shoName="Late Rehearsal", shoIsTimed=true;

# General admission shows
insert into shows set shoTime = "2011-09-30 19:30:00", shoClass = "REG", shoName="Regular Admission", shoCost = 1500, shoSellUntil = "947:20:00", shoId=701;
insert into shows set shoTime = "2011-09-30 19:30:00", shoClass = "VIP", shoName="VIP Admission", shoCost = 2000, shoSellUntil = "947:20:00", shoId=702;
insert into shows set shoTime = "2011-09-30 19:30:00", shoClass = "MSM", shoName="Museum Admission", shoCost = 500, shoSellUntil = "947:20:00", shoId=703;

# Rehearsal shows
insert into shows set shoTime = "2011-09-30 20:00:00", shoClass = "REG", shoName="Early Rehearsal", shoCost = 1500, shoSellUntil = "947:20:00", shoId=501;
insert into shows set shoTime = "2011-09-30 21:00:00", shoClass = "REG", shoName="Late Rehearsal", shoCost = 1500, shoSellUntil = "24:20:00", shoId=502;
insert into shows set shoTime = "2011-09-30 20:00:00", shoClass = "VIP", shoName="Early Rehearsal", shoCost = 1500, shoSellUntil = "24:20:00", shoId=503, shoIsTimed=true;
insert into shows set shoTime = "2011-09-30 21:00:00", shoClass = "VIP", shoName="Late Rehearsal", shoCost = 1500, shoSellUntil = "947:20:00", shoId=504, shoIsTimed=true;

# Rehearsal tickets
insert into tickets set shoId = 501, tixCode=1312, tixPool="b";
insert into tickets set shoId = 501, tixCode=3156, tixPool="b";
insert into tickets set shoId = 501, tixCode=4413, tixPool="b";
insert into tickets set shoId = 501, tixCode=7613, tixPool="b";
insert into tickets set shoId = 501, tixCode=1233, tixPool="b";
insert into tickets set shoId = 501, tixCode= 550, tixPool="b";
insert into tickets set shoId = 501, tixCode=1440, tixPool="b";
insert into tickets set shoId = 501, tixCode=9962, tixPool="b";
insert into tickets set shoId = 501, tixCode=8672, tixPool="b";
insert into tickets set shoId = 501, tixCode=2344, tixPool="b";

insert into tickets set shoId = 501, tixCode=2222, tixPool="w";
insert into tickets set shoId = 501, tixCode=2444, tixPool="w";
insert into tickets set shoId = 501, tixCode=9585, tixPool="w";
insert into tickets set shoId = 501, tixCode=8557, tixPool="w";
insert into tickets set shoId = 501, tixCode=4584, tixPool="w";
insert into tickets set shoId = 501, tixCode=2345, tixPool="w";
insert into tickets set shoId = 501, tixCode= 159, tixPool="w";
insert into tickets set shoId = 501, tixCode=4844, tixPool="w";
insert into tickets set shoId = 501, tixCode=1713, tixPool="w";
insert into tickets set shoId = 501, tixCode=2044, tixPool="w";

insert into tickets set shoId = 502, tixCode=1312, tixPool="b";
insert into tickets set shoId = 502, tixCode=3156, tixPool="b";
insert into tickets set shoId = 502, tixCode=4413, tixPool="b";
insert into tickets set shoId = 502, tixCode=7613, tixPool="b";
insert into tickets set shoId = 502, tixCode=1233, tixPool="b";
insert into tickets set shoId = 502, tixCode= 550, tixPool="b";
insert into tickets set shoId = 502, tixCode=1440, tixPool="b";
insert into tickets set shoId = 502, tixCode=9962, tixPool="b";
insert into tickets set shoId = 502, tixCode=8672, tixPool="b";
insert into tickets set shoId = 502, tixCode=2344, tixPool="b";

insert into tickets set shoId = 502, tixCode=2222, tixPool="w";
insert into tickets set shoId = 502, tixCode=2444, tixPool="w";
insert into tickets set shoId = 502, tixCode=9585, tixPool="w";
insert into tickets set shoId = 502, tixCode=8557, tixPool="w";
insert into tickets set shoId = 502, tixCode=4584, tixPool="w";
insert into tickets set shoId = 502, tixCode=2345, tixPool="w";
insert into tickets set shoId = 502, tixCode= 159, tixPool="w";
insert into tickets set shoId = 502, tixCode=4844, tixPool="w";
insert into tickets set shoId = 502, tixCode=1713, tixPool="w";
insert into tickets set shoId = 502, tixCode=2044, tixPool="w";

insert into tickets set shoId = 503, tixCode=1312, tixPool="b";
insert into tickets set shoId = 503, tixCode=3156, tixPool="b";
insert into tickets set shoId = 503, tixCode=4413, tixPool="b";
insert into tickets set shoId = 503, tixCode=7613, tixPool="b";
insert into tickets set shoId = 503, tixCode=1233, tixPool="b";
insert into tickets set shoId = 503, tixCode= 550, tixPool="b";
insert into tickets set shoId = 503, tixCode=1440, tixPool="b";
insert into tickets set shoId = 503, tixCode=9962, tixPool="b";
insert into tickets set shoId = 503, tixCode=8672, tixPool="b";
insert into tickets set shoId = 503, tixCode=2344, tixPool="b";

insert into tickets set shoId = 503, tixCode=2222, tixPool="w";
insert into tickets set shoId = 503, tixCode=2444, tixPool="w";
insert into tickets set shoId = 503, tixCode=9585, tixPool="w";
insert into tickets set shoId = 503, tixCode=8557, tixPool="w";
insert into tickets set shoId = 503, tixCode=4584, tixPool="w";
insert into tickets set shoId = 503, tixCode=2345, tixPool="w";
insert into tickets set shoId = 503, tixCode= 159, tixPool="w";
insert into tickets set shoId = 503, tixCode=4844, tixPool="w";
insert into tickets set shoId = 503, tixCode=1713, tixPool="w";
insert into tickets set shoId = 503, tixCode=2044, tixPool="w";

insert into tickets set shoId = 504, tixCode=1312, tixPool="b";
insert into tickets set shoId = 504, tixCode=3156, tixPool="b";
insert into tickets set shoId = 504, tixCode=4413, tixPool="b";
insert into tickets set shoId = 504, tixCode=7613, tixPool="b";
insert into tickets set shoId = 504, tixCode=1233, tixPool="b";
insert into tickets set shoId = 504, tixCode= 550, tixPool="b";
insert into tickets set shoId = 504, tixCode=1440, tixPool="b";
insert into tickets set shoId = 504, tixCode=9962, tixPool="b";
insert into tickets set shoId = 504, tixCode=8672, tixPool="b";
insert into tickets set shoId = 504, tixCode=2344, tixPool="b";

insert into tickets set shoId = 504, tixCode=2222, tixPool="w";
insert into tickets set shoId = 504, tixCode=2444, tixPool="w";
insert into tickets set shoId = 504, tixCode=9585, tixPool="w";
insert into tickets set shoId = 504, tixCode=8557, tixPool="w";
insert into tickets set shoId = 504, tixCode=4584, tixPool="w";
insert into tickets set shoId = 504, tixCode=2345, tixPool="w";
insert into tickets set shoId = 504, tixCode= 159, tixPool="w";
insert into tickets set shoId = 504, tixCode=4844, tixPool="w";
insert into tickets set shoId = 504, tixCode=1713, tixPool="w";
insert into tickets set shoId = 504, tixCode=2044, tixPool="w";


# Insert some starter AnyDay tickets... (use htx-mktix to generate tickets)
insert into tickets set shoId = 701, tixCode=1312, tixPool="b";
insert into tickets set shoId = 701, tixCode=3156, tixPool="b";
insert into tickets set shoId = 701, tixCode=4413, tixPool="b";
insert into tickets set shoId = 701, tixCode=7613, tixPool="b";
insert into tickets set shoId = 701, tixCode=1233, tixPool="b";
insert into tickets set shoId = 701, tixCode= 550, tixPool="b";
insert into tickets set shoId = 701, tixCode=1440, tixPool="b";
insert into tickets set shoId = 701, tixCode=9962, tixPool="b";
insert into tickets set shoId = 701, tixCode=8672, tixPool="b";
insert into tickets set shoId = 701, tixCode=2344, tixPool="b";

insert into tickets set shoId = 701, tixCode=2222, tixPool="w";
insert into tickets set shoId = 701, tixCode=2444, tixPool="w";
insert into tickets set shoId = 701, tixCode=9585, tixPool="w";
insert into tickets set shoId = 701, tixCode=8557, tixPool="w";
insert into tickets set shoId = 701, tixCode=4584, tixPool="w";
insert into tickets set shoId = 701, tixCode=2345, tixPool="w";
insert into tickets set shoId = 701, tixCode= 159, tixPool="w";
insert into tickets set shoId = 701, tixCode=4844, tixPool="w";
insert into tickets set shoId = 701, tixCode=1713, tixPool="w";
insert into tickets set shoId = 701, tixCode=2044, tixPool="w";


insert into tickets set shoId = 702, tixCode=7372, tixPool="b";
insert into tickets set shoId = 702, tixCode=3357, tixPool="b";
insert into tickets set shoId = 702, tixCode=2413, tixPool="b";
insert into tickets set shoId = 702, tixCode=2613, tixPool="b";
insert into tickets set shoId = 702, tixCode=1223, tixPool="b";
insert into tickets set shoId = 702, tixCode= 520, tixPool="b";
insert into tickets set shoId = 702, tixCode=1340, tixPool="b";
insert into tickets set shoId = 702, tixCode=9462, tixPool="b";
insert into tickets set shoId = 702, tixCode=8652, tixPool="b";
insert into tickets set shoId = 702, tixCode=2344, tixPool="b";

insert into tickets set shoId = 702, tixCode=2122, tixPool="w";
insert into tickets set shoId = 702, tixCode=2414, tixPool="w";
insert into tickets set shoId = 702, tixCode=9185, tixPool="w";
insert into tickets set shoId = 702, tixCode=8527, tixPool="w";
insert into tickets set shoId = 702, tixCode=4484, tixPool="w";
insert into tickets set shoId = 702, tixCode=2365, tixPool="w";
insert into tickets set shoId = 702, tixCode= 509, tixPool="w";
insert into tickets set shoId = 702, tixCode=4834, tixPool="w";
insert into tickets set shoId = 702, tixCode=1133, tixPool="w";
insert into tickets set shoId = 702, tixCode=2144, tixPool="w";


insert into tickets set shoId = 703, tixCode= 553, tixPool="b";
insert into tickets set shoId = 703, tixCode=1444, tixPool="b";
insert into tickets set shoId = 703, tixCode=9965, tixPool="b";
insert into tickets set shoId = 703, tixCode=8676, tixPool="b";
insert into tickets set shoId = 703, tixCode=2347, tixPool="b";

insert into tickets set shoId = 703, tixCode=2385, tixPool="w";
insert into tickets set shoId = 703, tixCode= 199, tixPool="w";
insert into tickets set shoId = 703, tixCode=4844, tixPool="w";
insert into tickets set shoId = 703, tixCode=1133, tixPool="w";
insert into tickets set shoId = 703, tixCode=2024, tixPool="w";



# Tickets for timed shows
insert into tickets set shoId = 1, tixCode=1312, tixPool="b";
insert into tickets set shoId = 1, tixCode=3156, tixPool="b";
insert into tickets set shoId = 1, tixCode=4413, tixPool="b";
insert into tickets set shoId = 1, tixCode=7613, tixPool="b";
insert into tickets set shoId = 1, tixCode=1233, tixPool="b";
insert into tickets set shoId = 1, tixCode= 550, tixPool="b";
insert into tickets set shoId = 1, tixCode=1440, tixPool="b";
insert into tickets set shoId = 1, tixCode=9962, tixPool="b";
insert into tickets set shoId = 1, tixCode=8672, tixPool="b";
insert into tickets set shoId = 1, tixCode=2344, tixPool="b";

insert into tickets set shoId = 1, tixCode=2222, tixPool="w";
insert into tickets set shoId = 1, tixCode=2444, tixPool="w";
insert into tickets set shoId = 1, tixCode=9585, tixPool="w";
insert into tickets set shoId = 1, tixCode=8557, tixPool="w";
insert into tickets set shoId = 1, tixCode=4584, tixPool="w";
insert into tickets set shoId = 1, tixCode=2345, tixPool="w";
insert into tickets set shoId = 1, tixCode= 109, tixPool="w";
insert into tickets set shoId = 1, tixCode=4844, tixPool="w";
insert into tickets set shoId = 1, tixCode=1113, tixPool="w";
insert into tickets set shoId = 1, tixCode=2044, tixPool="w";

insert into tickets set shoId = 2, tixCode=4884, tixPool="b";
insert into tickets set shoId = 2, tixCode=8289, tixPool="b";
insert into tickets set shoId = 2, tixCode=1335, tixPool="b";
insert into tickets set shoId = 2, tixCode=5522, tixPool="b";
insert into tickets set shoId = 2, tixCode=   7, tixPool="b";
insert into tickets set shoId = 2, tixCode=1235, tixPool="b";
insert into tickets set shoId = 2, tixCode=1255, tixPool="b";
insert into tickets set shoId = 2, tixCode=3713, tixPool="b";
insert into tickets set shoId = 2, tixCode=7713, tixPool="b";
insert into tickets set shoId = 2, tixCode=6778, tixPool="b";

insert into tickets set shoId = 2, tixCode=1453, tixPool="w";
insert into tickets set shoId = 2, tixCode=1233, tixPool="w";
insert into tickets set shoId = 2, tixCode=2344, tixPool="w";
insert into tickets set shoId = 2, tixCode=1314, tixPool="w";
insert into tickets set shoId = 2, tixCode=9908, tixPool="w";
insert into tickets set shoId = 2, tixCode=0404, tixPool="w";
insert into tickets set shoId = 2, tixCode=2341, tixPool="w";
insert into tickets set shoId = 2, tixCode=5665, tixPool="w";
insert into tickets set shoId = 2, tixCode=3455, tixPool="w";
insert into tickets set shoId = 2, tixCode=4667, tixPool="w";

insert into tickets set shoId = 3, tixCode=1312, tixPool="b";
insert into tickets set shoId = 3, tixCode=3156, tixPool="b";
insert into tickets set shoId = 3, tixCode=4413, tixPool="b";
insert into tickets set shoId = 3, tixCode=7613, tixPool="b";
insert into tickets set shoId = 3, tixCode=1233, tixPool="b";
insert into tickets set shoId = 3, tixCode= 550, tixPool="b";
insert into tickets set shoId = 3, tixCode=1440, tixPool="b";
insert into tickets set shoId = 3, tixCode=9962, tixPool="b";
insert into tickets set shoId = 3, tixCode=8672, tixPool="b";
insert into tickets set shoId = 3, tixCode=2344, tixPool="b";

insert into tickets set shoId = 3, tixCode=2222, tixPool="w";
insert into tickets set shoId = 3, tixCode=2444, tixPool="w";
insert into tickets set shoId = 3, tixCode=9585, tixPool="w";
insert into tickets set shoId = 3, tixCode=8557, tixPool="w";
insert into tickets set shoId = 3, tixCode=4584, tixPool="w";
insert into tickets set shoId = 3, tixCode=2345, tixPool="w";
insert into tickets set shoId = 3, tixCode= 109, tixPool="w";
insert into tickets set shoId = 3, tixCode=4844, tixPool="w";
insert into tickets set shoId = 3, tixCode=1113, tixPool="w";
insert into tickets set shoId = 3, tixCode=2044, tixPool="w";

insert into tickets set shoId = 4, tixCode=4884, tixPool="b";
insert into tickets set shoId = 4, tixCode=8289, tixPool="b";
insert into tickets set shoId = 4, tixCode=1335, tixPool="b";
insert into tickets set shoId = 4, tixCode=5522, tixPool="b";
insert into tickets set shoId = 4, tixCode=   7, tixPool="b";
insert into tickets set shoId = 4, tixCode=1235, tixPool="b";
insert into tickets set shoId = 4, tixCode=1255, tixPool="b";
insert into tickets set shoId = 4, tixCode=3713, tixPool="b";
insert into tickets set shoId = 4, tixCode=7713, tixPool="b";
insert into tickets set shoId = 4, tixCode=6778, tixPool="b";

insert into tickets set shoId = 4, tixCode=1453, tixPool="w";
insert into tickets set shoId = 4, tixCode=1233, tixPool="w";
insert into tickets set shoId = 4, tixCode=2344, tixPool="w";
insert into tickets set shoId = 4, tixCode=1314, tixPool="w";
insert into tickets set shoId = 4, tixCode=9908, tixPool="w";
insert into tickets set shoId = 4, tixCode=0404, tixPool="w";
insert into tickets set shoId = 4, tixCode=2341, tixPool="w";
insert into tickets set shoId = 4, tixCode=5665, tixPool="w";
insert into tickets set shoId = 4, tixCode=3455, tixPool="w";
insert into tickets set shoId = 4, tixCode=4667, tixPool="w";

insert into tickets set shoId = 5, tixCode=1312, tixPool="b";
insert into tickets set shoId = 5, tixCode=3156, tixPool="b";
insert into tickets set shoId = 5, tixCode=4413, tixPool="b";
insert into tickets set shoId = 5, tixCode=7613, tixPool="b";
insert into tickets set shoId = 5, tixCode=1233, tixPool="b";
insert into tickets set shoId = 5, tixCode= 550, tixPool="b";
insert into tickets set shoId = 5, tixCode=1440, tixPool="b";
insert into tickets set shoId = 5, tixCode=9962, tixPool="b";
insert into tickets set shoId = 5, tixCode=8672, tixPool="b";
insert into tickets set shoId = 5, tixCode=2344, tixPool="b";

insert into tickets set shoId = 5, tixCode=2222, tixPool="w";
insert into tickets set shoId = 5, tixCode=2444, tixPool="w";
insert into tickets set shoId = 5, tixCode=9585, tixPool="w";
insert into tickets set shoId = 5, tixCode=8557, tixPool="w";
insert into tickets set shoId = 5, tixCode=4584, tixPool="w";
insert into tickets set shoId = 5, tixCode=2345, tixPool="w";
insert into tickets set shoId = 5, tixCode= 109, tixPool="w";
insert into tickets set shoId = 5, tixCode=4844, tixPool="w";
insert into tickets set shoId = 5, tixCode=1113, tixPool="w";
insert into tickets set shoId = 5, tixCode=2044, tixPool="w";

insert into tickets set shoId = 6, tixCode=4884, tixPool="b";
insert into tickets set shoId = 6, tixCode=8289, tixPool="b";
insert into tickets set shoId = 6, tixCode=1335, tixPool="b";
insert into tickets set shoId = 6, tixCode=5522, tixPool="b";
insert into tickets set shoId = 6, tixCode=   7, tixPool="b";
insert into tickets set shoId = 6, tixCode=1235, tixPool="b";
insert into tickets set shoId = 6, tixCode=1255, tixPool="b";
insert into tickets set shoId = 6, tixCode=3713, tixPool="b";
insert into tickets set shoId = 6, tixCode=7713, tixPool="b";
insert into tickets set shoId = 6, tixCode=6778, tixPool="b";

insert into tickets set shoId = 6, tixCode=1453, tixPool="w";
insert into tickets set shoId = 6, tixCode=1233, tixPool="w";
insert into tickets set shoId = 6, tixCode=2344, tixPool="w";
insert into tickets set shoId = 6, tixCode=1314, tixPool="w";
insert into tickets set shoId = 6, tixCode=9908, tixPool="w";
insert into tickets set shoId = 6, tixCode=0404, tixPool="w";
insert into tickets set shoId = 6, tixCode=2341, tixPool="w";
insert into tickets set shoId = 6, tixCode=5665, tixPool="w";
insert into tickets set shoId = 6, tixCode=3455, tixPool="w";
insert into tickets set shoId = 6, tixCode=4667, tixPool="w";

insert into tickets set shoId = 7, tixCode=1312, tixPool="b";
insert into tickets set shoId = 7, tixCode=3156, tixPool="b";
insert into tickets set shoId = 7, tixCode=4413, tixPool="b";
insert into tickets set shoId = 7, tixCode=7613, tixPool="b";
insert into tickets set shoId = 7, tixCode=1233, tixPool="b";
insert into tickets set shoId = 7, tixCode= 550, tixPool="b";
insert into tickets set shoId = 7, tixCode=1440, tixPool="b";
insert into tickets set shoId = 7, tixCode=9962, tixPool="b";
insert into tickets set shoId = 7, tixCode=8672, tixPool="b";
insert into tickets set shoId = 7, tixCode=2344, tixPool="b";

insert into tickets set shoId = 7, tixCode=2222, tixPool="w";
insert into tickets set shoId = 7, tixCode=2444, tixPool="w";
insert into tickets set shoId = 7, tixCode=9585, tixPool="w";
insert into tickets set shoId = 7, tixCode=8557, tixPool="w";
insert into tickets set shoId = 7, tixCode=4584, tixPool="w";
insert into tickets set shoId = 7, tixCode=2345, tixPool="w";
insert into tickets set shoId = 7, tixCode= 109, tixPool="w";
insert into tickets set shoId = 7, tixCode=4844, tixPool="w";
insert into tickets set shoId = 7, tixCode=1113, tixPool="w";
insert into tickets set shoId = 7, tixCode=2044, tixPool="w";

insert into tickets set shoId = 8, tixCode=4884, tixPool="b";
insert into tickets set shoId = 8, tixCode=8289, tixPool="b";
insert into tickets set shoId = 8, tixCode=1335, tixPool="b";
insert into tickets set shoId = 8, tixCode=5522, tixPool="b";
insert into tickets set shoId = 8, tixCode=   7, tixPool="b";
insert into tickets set shoId = 8, tixCode=1235, tixPool="b";
insert into tickets set shoId = 8, tixCode=1255, tixPool="b";
insert into tickets set shoId = 8, tixCode=3713, tixPool="b";
insert into tickets set shoId = 8, tixCode=7713, tixPool="b";
insert into tickets set shoId = 8, tixCode=6778, tixPool="b";

insert into tickets set shoId = 8, tixCode=1453, tixPool="w";
insert into tickets set shoId = 8, tixCode=1233, tixPool="w";
insert into tickets set shoId = 8, tixCode=2344, tixPool="w";
insert into tickets set shoId = 8, tixCode=1314, tixPool="w";
insert into tickets set shoId = 8, tixCode=9908, tixPool="w";
insert into tickets set shoId = 8, tixCode=0404, tixPool="w";
insert into tickets set shoId = 8, tixCode=2341, tixPool="w";
insert into tickets set shoId = 8, tixCode=5665, tixPool="w";
insert into tickets set shoId = 8, tixCode=3455, tixPool="w";
insert into tickets set shoId = 8, tixCode=4667, tixPool="w";


insert into tickets set shoId = 21, tixCode=1312, tixPool="b";
insert into tickets set shoId = 21, tixCode=3156, tixPool="b";
insert into tickets set shoId = 21, tixCode=4413, tixPool="b";
insert into tickets set shoId = 21, tixCode=7613, tixPool="b";
insert into tickets set shoId = 21, tixCode=1233, tixPool="b";
insert into tickets set shoId = 21, tixCode= 550, tixPool="b";
insert into tickets set shoId = 21, tixCode=1440, tixPool="b";
insert into tickets set shoId = 21, tixCode=9962, tixPool="b";
insert into tickets set shoId = 21, tixCode=8672, tixPool="b";
insert into tickets set shoId = 21, tixCode=2344, tixPool="b";

insert into tickets set shoId = 21, tixCode=2222, tixPool="w";
insert into tickets set shoId = 21, tixCode=2444, tixPool="w";
insert into tickets set shoId = 21, tixCode=9585, tixPool="w";
insert into tickets set shoId = 21, tixCode=8557, tixPool="w";
insert into tickets set shoId = 21, tixCode=4584, tixPool="w";
insert into tickets set shoId = 21, tixCode=2345, tixPool="w";
insert into tickets set shoId = 21, tixCode= 109, tixPool="w";
insert into tickets set shoId = 21, tixCode=4844, tixPool="w";
insert into tickets set shoId = 21, tixCode=1113, tixPool="w";
insert into tickets set shoId = 21, tixCode=2044, tixPool="w";

insert into tickets set shoId = 22, tixCode=4884, tixPool="b";
insert into tickets set shoId = 22, tixCode=8289, tixPool="b";
insert into tickets set shoId = 22, tixCode=1335, tixPool="b";
insert into tickets set shoId = 22, tixCode=5522, tixPool="b";
insert into tickets set shoId = 22, tixCode=   7, tixPool="b";
insert into tickets set shoId = 22, tixCode=1235, tixPool="b";
insert into tickets set shoId = 22, tixCode=1255, tixPool="b";
insert into tickets set shoId = 22, tixCode=3713, tixPool="b";
insert into tickets set shoId = 22, tixCode=7713, tixPool="b";
insert into tickets set shoId = 22, tixCode=6778, tixPool="b";

insert into tickets set shoId = 22, tixCode=1453, tixPool="w";
insert into tickets set shoId = 22, tixCode=1233, tixPool="w";
insert into tickets set shoId = 22, tixCode=2344, tixPool="w";
insert into tickets set shoId = 22, tixCode=1314, tixPool="w";
insert into tickets set shoId = 22, tixCode=9908, tixPool="w";
insert into tickets set shoId = 22, tixCode=0404, tixPool="w";
insert into tickets set shoId = 22, tixCode=2341, tixPool="w";
insert into tickets set shoId = 22, tixCode=5665, tixPool="w";
insert into tickets set shoId = 22, tixCode=3455, tixPool="w";
insert into tickets set shoId = 22, tixCode=4667, tixPool="w";

insert into tickets set shoId = 23, tixCode=1312, tixPool="b";
insert into tickets set shoId = 23, tixCode=3156, tixPool="b";
insert into tickets set shoId = 23, tixCode=4413, tixPool="b";
insert into tickets set shoId = 23, tixCode=7613, tixPool="b";
insert into tickets set shoId = 23, tixCode=1233, tixPool="b";
insert into tickets set shoId = 23, tixCode= 550, tixPool="b";
insert into tickets set shoId = 23, tixCode=1440, tixPool="b";
insert into tickets set shoId = 23, tixCode=9962, tixPool="b";
insert into tickets set shoId = 23, tixCode=8672, tixPool="b";
insert into tickets set shoId = 23, tixCode=2344, tixPool="b";

insert into tickets set shoId = 23, tixCode=2222, tixPool="w";
insert into tickets set shoId = 23, tixCode=2444, tixPool="w";
insert into tickets set shoId = 23, tixCode=9585, tixPool="w";
insert into tickets set shoId = 23, tixCode=8557, tixPool="w";
insert into tickets set shoId = 23, tixCode=4584, tixPool="w";
insert into tickets set shoId = 23, tixCode=2345, tixPool="w";
insert into tickets set shoId = 23, tixCode= 109, tixPool="w";
insert into tickets set shoId = 23, tixCode=4844, tixPool="w";
insert into tickets set shoId = 23, tixCode=1113, tixPool="w";
insert into tickets set shoId = 23, tixCode=2044, tixPool="w";

insert into tickets set shoId = 24, tixCode=4884, tixPool="b";
insert into tickets set shoId = 24, tixCode=8289, tixPool="b";
insert into tickets set shoId = 24, tixCode=1335, tixPool="b";
insert into tickets set shoId = 24, tixCode=5522, tixPool="b";
insert into tickets set shoId = 24, tixCode=   7, tixPool="b";
insert into tickets set shoId = 24, tixCode=1235, tixPool="b";
insert into tickets set shoId = 24, tixCode=1255, tixPool="b";
insert into tickets set shoId = 24, tixCode=3713, tixPool="b";
insert into tickets set shoId = 24, tixCode=7713, tixPool="b";
insert into tickets set shoId = 24, tixCode=6778, tixPool="b";

insert into tickets set shoId = 24, tixCode=1453, tixPool="w";
insert into tickets set shoId = 24, tixCode=1233, tixPool="w";
insert into tickets set shoId = 24, tixCode=2344, tixPool="w";
insert into tickets set shoId = 24, tixCode=1314, tixPool="w";
insert into tickets set shoId = 24, tixCode=9908, tixPool="w";
insert into tickets set shoId = 24, tixCode=0404, tixPool="w";
insert into tickets set shoId = 24, tixCode=2341, tixPool="w";
insert into tickets set shoId = 24, tixCode=5665, tixPool="w";
insert into tickets set shoId = 24, tixCode=3455, tixPool="w";
insert into tickets set shoId = 24, tixCode=4667, tixPool="w";

insert into tickets set shoId = 25, tixCode=1312, tixPool="b";
insert into tickets set shoId = 25, tixCode=3156, tixPool="b";
insert into tickets set shoId = 25, tixCode=4413, tixPool="b";
insert into tickets set shoId = 25, tixCode=7613, tixPool="b";
insert into tickets set shoId = 25, tixCode=1233, tixPool="b";
insert into tickets set shoId = 25, tixCode= 550, tixPool="b";
insert into tickets set shoId = 25, tixCode=1440, tixPool="b";
insert into tickets set shoId = 25, tixCode=9962, tixPool="b";
insert into tickets set shoId = 25, tixCode=8672, tixPool="b";
insert into tickets set shoId = 25, tixCode=2344, tixPool="b";

insert into tickets set shoId = 25, tixCode=2222, tixPool="w";
insert into tickets set shoId = 25, tixCode=2444, tixPool="w";
insert into tickets set shoId = 25, tixCode=9585, tixPool="w";
insert into tickets set shoId = 25, tixCode=8557, tixPool="w";
insert into tickets set shoId = 25, tixCode=4584, tixPool="w";
insert into tickets set shoId = 25, tixCode=2345, tixPool="w";
insert into tickets set shoId = 25, tixCode= 109, tixPool="w";
insert into tickets set shoId = 25, tixCode=4844, tixPool="w";
insert into tickets set shoId = 25, tixCode=1113, tixPool="w";
insert into tickets set shoId = 25, tixCode=2044, tixPool="w";

insert into tickets set shoId = 26, tixCode=4884, tixPool="b";
insert into tickets set shoId = 26, tixCode=8289, tixPool="b";
insert into tickets set shoId = 26, tixCode=1335, tixPool="b";
insert into tickets set shoId = 26, tixCode=5522, tixPool="b";
insert into tickets set shoId = 26, tixCode=   7, tixPool="b";
insert into tickets set shoId = 26, tixCode=1235, tixPool="b";
insert into tickets set shoId = 26, tixCode=1255, tixPool="b";
insert into tickets set shoId = 26, tixCode=3713, tixPool="b";
insert into tickets set shoId = 26, tixCode=7713, tixPool="b";
insert into tickets set shoId = 26, tixCode=6778, tixPool="b";

insert into tickets set shoId = 26, tixCode=1453, tixPool="w";
insert into tickets set shoId = 26, tixCode=1233, tixPool="w";
insert into tickets set shoId = 26, tixCode=2344, tixPool="w";
insert into tickets set shoId = 26, tixCode=1314, tixPool="w";
insert into tickets set shoId = 26, tixCode=9908, tixPool="w";
insert into tickets set shoId = 26, tixCode=0404, tixPool="w";
insert into tickets set shoId = 26, tixCode=2341, tixPool="w";
insert into tickets set shoId = 26, tixCode=5665, tixPool="w";
insert into tickets set shoId = 26, tixCode=3455, tixPool="w";
insert into tickets set shoId = 26, tixCode=4667, tixPool="w";

insert into tickets set shoId = 27, tixCode=1312, tixPool="b";
insert into tickets set shoId = 27, tixCode=3156, tixPool="b";
insert into tickets set shoId = 27, tixCode=4413, tixPool="b";
insert into tickets set shoId = 27, tixCode=7613, tixPool="b";
insert into tickets set shoId = 27, tixCode=1233, tixPool="b";
insert into tickets set shoId = 27, tixCode= 550, tixPool="b";
insert into tickets set shoId = 27, tixCode=1440, tixPool="b";
insert into tickets set shoId = 27, tixCode=9962, tixPool="b";
insert into tickets set shoId = 27, tixCode=8672, tixPool="b";
insert into tickets set shoId = 27, tixCode=2344, tixPool="b";

insert into tickets set shoId = 27, tixCode=2222, tixPool="w";
insert into tickets set shoId = 27, tixCode=2444, tixPool="w";
insert into tickets set shoId = 27, tixCode=9585, tixPool="w";
insert into tickets set shoId = 27, tixCode=8557, tixPool="w";
insert into tickets set shoId = 27, tixCode=4584, tixPool="w";
insert into tickets set shoId = 27, tixCode=2345, tixPool="w";
insert into tickets set shoId = 27, tixCode= 109, tixPool="w";
insert into tickets set shoId = 27, tixCode=4844, tixPool="w";
insert into tickets set shoId = 27, tixCode=1113, tixPool="w";
insert into tickets set shoId = 27, tixCode=2044, tixPool="w";

insert into tickets set shoId = 28, tixCode=4884, tixPool="b";
insert into tickets set shoId = 28, tixCode=8289, tixPool="b";
insert into tickets set shoId = 28, tixCode=1335, tixPool="b";
insert into tickets set shoId = 28, tixCode=5522, tixPool="b";
insert into tickets set shoId = 28, tixCode=   7, tixPool="b";
insert into tickets set shoId = 28, tixCode=1235, tixPool="b";
insert into tickets set shoId = 28, tixCode=1255, tixPool="b";
insert into tickets set shoId = 28, tixCode=3713, tixPool="b";
insert into tickets set shoId = 28, tixCode=7713, tixPool="b";
insert into tickets set shoId = 28, tixCode=6778, tixPool="b";

insert into tickets set shoId = 28, tixCode=1453, tixPool="w";
insert into tickets set shoId = 28, tixCode=1233, tixPool="w";
insert into tickets set shoId = 28, tixCode=2344, tixPool="w";
insert into tickets set shoId = 28, tixCode=1314, tixPool="w";
insert into tickets set shoId = 28, tixCode=9908, tixPool="w";
insert into tickets set shoId = 28, tixCode=0404, tixPool="w";
insert into tickets set shoId = 28, tixCode=2341, tixPool="w";
insert into tickets set shoId = 28, tixCode=5665, tixPool="w";
insert into tickets set shoId = 28, tixCode=3455, tixPool="w";
insert into tickets set shoId = 28, tixCode=4667, tixPool="w";


insert into tickets set shoId = 41, tixCode=1312, tixPool="b";
insert into tickets set shoId = 41, tixCode=3156, tixPool="b";
insert into tickets set shoId = 41, tixCode=4413, tixPool="b";
insert into tickets set shoId = 41, tixCode=7613, tixPool="b";
insert into tickets set shoId = 41, tixCode=1233, tixPool="b";
insert into tickets set shoId = 41, tixCode= 550, tixPool="b";
insert into tickets set shoId = 41, tixCode=1440, tixPool="b";
insert into tickets set shoId = 41, tixCode=9962, tixPool="b";
insert into tickets set shoId = 41, tixCode=8672, tixPool="b";
insert into tickets set shoId = 41, tixCode=2344, tixPool="b";

insert into tickets set shoId = 41, tixCode=2222, tixPool="w";
insert into tickets set shoId = 41, tixCode=2444, tixPool="w";
insert into tickets set shoId = 41, tixCode=9585, tixPool="w";
insert into tickets set shoId = 41, tixCode=8557, tixPool="w";
insert into tickets set shoId = 41, tixCode=4584, tixPool="w";
insert into tickets set shoId = 41, tixCode=2345, tixPool="w";
insert into tickets set shoId = 41, tixCode= 109, tixPool="w";
insert into tickets set shoId = 41, tixCode=4844, tixPool="w";
insert into tickets set shoId = 41, tixCode=1113, tixPool="w";
insert into tickets set shoId = 41, tixCode=2044, tixPool="w";

insert into tickets set shoId = 42, tixCode=4884, tixPool="b";
insert into tickets set shoId = 42, tixCode=8289, tixPool="b";
insert into tickets set shoId = 42, tixCode=1335, tixPool="b";
insert into tickets set shoId = 42, tixCode=5522, tixPool="b";
insert into tickets set shoId = 42, tixCode=   7, tixPool="b";
insert into tickets set shoId = 42, tixCode=1235, tixPool="b";
insert into tickets set shoId = 42, tixCode=1255, tixPool="b";
insert into tickets set shoId = 42, tixCode=3713, tixPool="b";
insert into tickets set shoId = 42, tixCode=7713, tixPool="b";
insert into tickets set shoId = 42, tixCode=6778, tixPool="b";

insert into tickets set shoId = 42, tixCode=1453, tixPool="w";
insert into tickets set shoId = 42, tixCode=1233, tixPool="w";
insert into tickets set shoId = 42, tixCode=2344, tixPool="w";
insert into tickets set shoId = 42, tixCode=1314, tixPool="w";
insert into tickets set shoId = 42, tixCode=9908, tixPool="w";
insert into tickets set shoId = 42, tixCode=0404, tixPool="w";
insert into tickets set shoId = 42, tixCode=2341, tixPool="w";
insert into tickets set shoId = 42, tixCode=5665, tixPool="w";
insert into tickets set shoId = 42, tixCode=3455, tixPool="w";
insert into tickets set shoId = 42, tixCode=4667, tixPool="w";

insert into tickets set shoId = 43, tixCode=1312, tixPool="b";
insert into tickets set shoId = 43, tixCode=3156, tixPool="b";
insert into tickets set shoId = 43, tixCode=4413, tixPool="b";
insert into tickets set shoId = 43, tixCode=7613, tixPool="b";
insert into tickets set shoId = 43, tixCode=1233, tixPool="b";
insert into tickets set shoId = 43, tixCode= 550, tixPool="b";
insert into tickets set shoId = 43, tixCode=1440, tixPool="b";
insert into tickets set shoId = 43, tixCode=9962, tixPool="b";
insert into tickets set shoId = 43, tixCode=8672, tixPool="b";
insert into tickets set shoId = 43, tixCode=2344, tixPool="b";

insert into tickets set shoId = 43, tixCode=2222, tixPool="w";
insert into tickets set shoId = 43, tixCode=2444, tixPool="w";
insert into tickets set shoId = 43, tixCode=9585, tixPool="w";
insert into tickets set shoId = 43, tixCode=8557, tixPool="w";
insert into tickets set shoId = 43, tixCode=4584, tixPool="w";
insert into tickets set shoId = 43, tixCode=2345, tixPool="w";
insert into tickets set shoId = 43, tixCode= 109, tixPool="w";
insert into tickets set shoId = 43, tixCode=4844, tixPool="w";
insert into tickets set shoId = 43, tixCode=1113, tixPool="w";
insert into tickets set shoId = 43, tixCode=2044, tixPool="w";

insert into tickets set shoId = 44, tixCode=4884, tixPool="b";
insert into tickets set shoId = 44, tixCode=8289, tixPool="b";
insert into tickets set shoId = 44, tixCode=1335, tixPool="b";
insert into tickets set shoId = 44, tixCode=5522, tixPool="b";
insert into tickets set shoId = 44, tixCode=   7, tixPool="b";
insert into tickets set shoId = 44, tixCode=1235, tixPool="b";
insert into tickets set shoId = 44, tixCode=1255, tixPool="b";
insert into tickets set shoId = 44, tixCode=3713, tixPool="b";
insert into tickets set shoId = 44, tixCode=7713, tixPool="b";
insert into tickets set shoId = 44, tixCode=6778, tixPool="b";

insert into tickets set shoId = 44, tixCode=1453, tixPool="w";
insert into tickets set shoId = 44, tixCode=1233, tixPool="w";
insert into tickets set shoId = 44, tixCode=2344, tixPool="w";
insert into tickets set shoId = 44, tixCode=1314, tixPool="w";
insert into tickets set shoId = 44, tixCode=9908, tixPool="w";
insert into tickets set shoId = 44, tixCode=0404, tixPool="w";
insert into tickets set shoId = 44, tixCode=2341, tixPool="w";
insert into tickets set shoId = 44, tixCode=5665, tixPool="w";
insert into tickets set shoId = 44, tixCode=3455, tixPool="w";
insert into tickets set shoId = 44, tixCode=4667, tixPool="w";

insert into tickets set shoId = 45, tixCode=1312, tixPool="b";
insert into tickets set shoId = 45, tixCode=3156, tixPool="b";
insert into tickets set shoId = 45, tixCode=4413, tixPool="b";
insert into tickets set shoId = 45, tixCode=7613, tixPool="b";
insert into tickets set shoId = 45, tixCode=1233, tixPool="b";
insert into tickets set shoId = 45, tixCode= 550, tixPool="b";
insert into tickets set shoId = 45, tixCode=1440, tixPool="b";
insert into tickets set shoId = 45, tixCode=9962, tixPool="b";
insert into tickets set shoId = 45, tixCode=8672, tixPool="b";
insert into tickets set shoId = 45, tixCode=2344, tixPool="b";

insert into tickets set shoId = 45, tixCode=2222, tixPool="w";
insert into tickets set shoId = 45, tixCode=2444, tixPool="w";
insert into tickets set shoId = 45, tixCode=9585, tixPool="w";
insert into tickets set shoId = 45, tixCode=8557, tixPool="w";
insert into tickets set shoId = 45, tixCode=4584, tixPool="w";
insert into tickets set shoId = 45, tixCode=2345, tixPool="w";
insert into tickets set shoId = 45, tixCode= 109, tixPool="w";
insert into tickets set shoId = 45, tixCode=4844, tixPool="w";
insert into tickets set shoId = 45, tixCode=1113, tixPool="w";
insert into tickets set shoId = 45, tixCode=2044, tixPool="w";

insert into tickets set shoId = 46, tixCode=4884, tixPool="b";
insert into tickets set shoId = 46, tixCode=8289, tixPool="b";
insert into tickets set shoId = 46, tixCode=1335, tixPool="b";
insert into tickets set shoId = 46, tixCode=5522, tixPool="b";
insert into tickets set shoId = 46, tixCode=   7, tixPool="b";
insert into tickets set shoId = 46, tixCode=1235, tixPool="b";
insert into tickets set shoId = 46, tixCode=1255, tixPool="b";
insert into tickets set shoId = 46, tixCode=3713, tixPool="b";
insert into tickets set shoId = 46, tixCode=7713, tixPool="b";
insert into tickets set shoId = 46, tixCode=6778, tixPool="b";

insert into tickets set shoId = 46, tixCode=1453, tixPool="w";
insert into tickets set shoId = 46, tixCode=1233, tixPool="w";
insert into tickets set shoId = 46, tixCode=2344, tixPool="w";
insert into tickets set shoId = 46, tixCode=1314, tixPool="w";
insert into tickets set shoId = 46, tixCode=9908, tixPool="w";
insert into tickets set shoId = 46, tixCode=0404, tixPool="w";
insert into tickets set shoId = 46, tixCode=2341, tixPool="w";
insert into tickets set shoId = 46, tixCode=5665, tixPool="w";
insert into tickets set shoId = 46, tixCode=3455, tixPool="w";
insert into tickets set shoId = 46, tixCode=4667, tixPool="w";

insert into tickets set shoId = 47, tixCode=1312, tixPool="b";
insert into tickets set shoId = 47, tixCode=3156, tixPool="b";
insert into tickets set shoId = 47, tixCode=4413, tixPool="b";
insert into tickets set shoId = 47, tixCode=7613, tixPool="b";
insert into tickets set shoId = 47, tixCode=1233, tixPool="b";
insert into tickets set shoId = 47, tixCode= 550, tixPool="b";
insert into tickets set shoId = 47, tixCode=1440, tixPool="b";
insert into tickets set shoId = 47, tixCode=9962, tixPool="b";
insert into tickets set shoId = 47, tixCode=8672, tixPool="b";
insert into tickets set shoId = 47, tixCode=2344, tixPool="b";

insert into tickets set shoId = 47, tixCode=2222, tixPool="w";
insert into tickets set shoId = 47, tixCode=2444, tixPool="w";
insert into tickets set shoId = 47, tixCode=9585, tixPool="w";
insert into tickets set shoId = 47, tixCode=8557, tixPool="w";
insert into tickets set shoId = 47, tixCode=4584, tixPool="w";
insert into tickets set shoId = 47, tixCode=2345, tixPool="w";
insert into tickets set shoId = 47, tixCode= 109, tixPool="w";
insert into tickets set shoId = 47, tixCode=4844, tixPool="w";
insert into tickets set shoId = 47, tixCode=1113, tixPool="w";
insert into tickets set shoId = 47, tixCode=2044, tixPool="w";

insert into tickets set shoId = 48, tixCode=4884, tixPool="b";
insert into tickets set shoId = 48, tixCode=8289, tixPool="b";
insert into tickets set shoId = 48, tixCode=1335, tixPool="b";
insert into tickets set shoId = 48, tixCode=5522, tixPool="b";
insert into tickets set shoId = 48, tixCode=   7, tixPool="b";
insert into tickets set shoId = 48, tixCode=1235, tixPool="b";
insert into tickets set shoId = 48, tixCode=1255, tixPool="b";
insert into tickets set shoId = 48, tixCode=3713, tixPool="b";
insert into tickets set shoId = 48, tixCode=7713, tixPool="b";
insert into tickets set shoId = 48, tixCode=6778, tixPool="b";

insert into tickets set shoId = 48, tixCode=1453, tixPool="w";
insert into tickets set shoId = 48, tixCode=1233, tixPool="w";
insert into tickets set shoId = 48, tixCode=2344, tixPool="w";
insert into tickets set shoId = 48, tixCode=1314, tixPool="w";
insert into tickets set shoId = 48, tixCode=9908, tixPool="w";
insert into tickets set shoId = 48, tixCode=0404, tixPool="w";
insert into tickets set shoId = 48, tixCode=2341, tixPool="w";
insert into tickets set shoId = 48, tixCode=5665, tixPool="w";
insert into tickets set shoId = 48, tixCode=3455, tixPool="w";
insert into tickets set shoId = 48, tixCode=4667, tixPool="w";

insert into tickets set shoId = 61, tixCode=1312, tixPool="b";
insert into tickets set shoId = 61, tixCode=3156, tixPool="b";
insert into tickets set shoId = 61, tixCode=4413, tixPool="b";
insert into tickets set shoId = 61, tixCode=7613, tixPool="b";
insert into tickets set shoId = 61, tixCode=1233, tixPool="b";
insert into tickets set shoId = 61, tixCode= 550, tixPool="b";
insert into tickets set shoId = 61, tixCode=1440, tixPool="b";
insert into tickets set shoId = 61, tixCode=9962, tixPool="b";
insert into tickets set shoId = 61, tixCode=8672, tixPool="b";
insert into tickets set shoId = 61, tixCode=2344, tixPool="b";

insert into tickets set shoId = 61, tixCode=2222, tixPool="w";
insert into tickets set shoId = 61, tixCode=2444, tixPool="w";
insert into tickets set shoId = 61, tixCode=9585, tixPool="w";
insert into tickets set shoId = 61, tixCode=8557, tixPool="w";
insert into tickets set shoId = 61, tixCode=4584, tixPool="w";
insert into tickets set shoId = 61, tixCode=2345, tixPool="w";
insert into tickets set shoId = 61, tixCode= 109, tixPool="w";
insert into tickets set shoId = 61, tixCode=4844, tixPool="w";
insert into tickets set shoId = 61, tixCode=1113, tixPool="w";
insert into tickets set shoId = 61, tixCode=2044, tixPool="w";

insert into tickets set shoId = 62, tixCode=4884, tixPool="b";
insert into tickets set shoId = 62, tixCode=8289, tixPool="b";
insert into tickets set shoId = 62, tixCode=1335, tixPool="b";
insert into tickets set shoId = 62, tixCode=5522, tixPool="b";
insert into tickets set shoId = 62, tixCode=   7, tixPool="b";
insert into tickets set shoId = 62, tixCode=1235, tixPool="b";
insert into tickets set shoId = 62, tixCode=1255, tixPool="b";
insert into tickets set shoId = 62, tixCode=3713, tixPool="b";
insert into tickets set shoId = 62, tixCode=7713, tixPool="b";
insert into tickets set shoId = 62, tixCode=6778, tixPool="b";

insert into tickets set shoId = 62, tixCode=1453, tixPool="w";
insert into tickets set shoId = 62, tixCode=1233, tixPool="w";
insert into tickets set shoId = 62, tixCode=2344, tixPool="w";
insert into tickets set shoId = 62, tixCode=1314, tixPool="w";
insert into tickets set shoId = 62, tixCode=9908, tixPool="w";
insert into tickets set shoId = 62, tixCode=0404, tixPool="w";
insert into tickets set shoId = 62, tixCode=2341, tixPool="w";
insert into tickets set shoId = 62, tixCode=5665, tixPool="w";
insert into tickets set shoId = 62, tixCode=3455, tixPool="w";
insert into tickets set shoId = 62, tixCode=4667, tixPool="w";

insert into tickets set shoId = 63, tixCode=1312, tixPool="b";
insert into tickets set shoId = 63, tixCode=3156, tixPool="b";
insert into tickets set shoId = 63, tixCode=4413, tixPool="b";
insert into tickets set shoId = 63, tixCode=7613, tixPool="b";
insert into tickets set shoId = 63, tixCode=1233, tixPool="b";
insert into tickets set shoId = 63, tixCode= 550, tixPool="b";
insert into tickets set shoId = 63, tixCode=1440, tixPool="b";
insert into tickets set shoId = 63, tixCode=9962, tixPool="b";
insert into tickets set shoId = 63, tixCode=8672, tixPool="b";
insert into tickets set shoId = 63, tixCode=2344, tixPool="b";

insert into tickets set shoId = 63, tixCode=2222, tixPool="w";
insert into tickets set shoId = 63, tixCode=2444, tixPool="w";
insert into tickets set shoId = 63, tixCode=9585, tixPool="w";
insert into tickets set shoId = 63, tixCode=8557, tixPool="w";
insert into tickets set shoId = 63, tixCode=4584, tixPool="w";
insert into tickets set shoId = 63, tixCode=2345, tixPool="w";
insert into tickets set shoId = 63, tixCode= 109, tixPool="w";
insert into tickets set shoId = 63, tixCode=4844, tixPool="w";
insert into tickets set shoId = 63, tixCode=1113, tixPool="w";
insert into tickets set shoId = 63, tixCode=2044, tixPool="w";

insert into tickets set shoId = 64, tixCode=4884, tixPool="b";
insert into tickets set shoId = 64, tixCode=8289, tixPool="b";
insert into tickets set shoId = 64, tixCode=1335, tixPool="b";
insert into tickets set shoId = 64, tixCode=5522, tixPool="b";
insert into tickets set shoId = 64, tixCode=   7, tixPool="b";
insert into tickets set shoId = 64, tixCode=1235, tixPool="b";
insert into tickets set shoId = 64, tixCode=1255, tixPool="b";
insert into tickets set shoId = 64, tixCode=3713, tixPool="b";
insert into tickets set shoId = 64, tixCode=7713, tixPool="b";
insert into tickets set shoId = 64, tixCode=6778, tixPool="b";

insert into tickets set shoId = 64, tixCode=1453, tixPool="w";
insert into tickets set shoId = 64, tixCode=1233, tixPool="w";
insert into tickets set shoId = 64, tixCode=2344, tixPool="w";
insert into tickets set shoId = 64, tixCode=1314, tixPool="w";
insert into tickets set shoId = 64, tixCode=9908, tixPool="w";
insert into tickets set shoId = 64, tixCode=0404, tixPool="w";
insert into tickets set shoId = 64, tixCode=2341, tixPool="w";
insert into tickets set shoId = 64, tixCode=5665, tixPool="w";
insert into tickets set shoId = 64, tixCode=3455, tixPool="w";
insert into tickets set shoId = 64, tixCode=4667, tixPool="w";

insert into tickets set shoId = 65, tixCode=1312, tixPool="b";
insert into tickets set shoId = 65, tixCode=3156, tixPool="b";
insert into tickets set shoId = 65, tixCode=4413, tixPool="b";
insert into tickets set shoId = 65, tixCode=7613, tixPool="b";
insert into tickets set shoId = 65, tixCode=1233, tixPool="b";
insert into tickets set shoId = 65, tixCode= 550, tixPool="b";
insert into tickets set shoId = 65, tixCode=1440, tixPool="b";
insert into tickets set shoId = 65, tixCode=9962, tixPool="b";
insert into tickets set shoId = 65, tixCode=8672, tixPool="b";
insert into tickets set shoId = 65, tixCode=2344, tixPool="b";

insert into tickets set shoId = 65, tixCode=2222, tixPool="w";
insert into tickets set shoId = 65, tixCode=2444, tixPool="w";
insert into tickets set shoId = 65, tixCode=9585, tixPool="w";
insert into tickets set shoId = 65, tixCode=8557, tixPool="w";
insert into tickets set shoId = 65, tixCode=4584, tixPool="w";
insert into tickets set shoId = 65, tixCode=2345, tixPool="w";
insert into tickets set shoId = 65, tixCode= 109, tixPool="w";
insert into tickets set shoId = 65, tixCode=4844, tixPool="w";
insert into tickets set shoId = 65, tixCode=1113, tixPool="w";
insert into tickets set shoId = 65, tixCode=2044, tixPool="w";

insert into tickets set shoId = 66, tixCode=4884, tixPool="b";
insert into tickets set shoId = 66, tixCode=8289, tixPool="b";
insert into tickets set shoId = 66, tixCode=1335, tixPool="b";
insert into tickets set shoId = 66, tixCode=5522, tixPool="b";
insert into tickets set shoId = 66, tixCode=   7, tixPool="b";
insert into tickets set shoId = 66, tixCode=1235, tixPool="b";
insert into tickets set shoId = 66, tixCode=1255, tixPool="b";
insert into tickets set shoId = 66, tixCode=3713, tixPool="b";
insert into tickets set shoId = 66, tixCode=7713, tixPool="b";
insert into tickets set shoId = 66, tixCode=6778, tixPool="b";

insert into tickets set shoId = 66, tixCode=1453, tixPool="w";
insert into tickets set shoId = 66, tixCode=1233, tixPool="w";
insert into tickets set shoId = 66, tixCode=2344, tixPool="w";
insert into tickets set shoId = 66, tixCode=1314, tixPool="w";
insert into tickets set shoId = 66, tixCode=9908, tixPool="w";
insert into tickets set shoId = 66, tixCode=0404, tixPool="w";
insert into tickets set shoId = 66, tixCode=2341, tixPool="w";
insert into tickets set shoId = 66, tixCode=5665, tixPool="w";
insert into tickets set shoId = 66, tixCode=3455, tixPool="w";
insert into tickets set shoId = 66, tixCode=4667, tixPool="w";

insert into tickets set shoId = 67, tixCode=1312, tixPool="b";
insert into tickets set shoId = 67, tixCode=3156, tixPool="b";
insert into tickets set shoId = 67, tixCode=4413, tixPool="b";
insert into tickets set shoId = 67, tixCode=7613, tixPool="b";
insert into tickets set shoId = 67, tixCode=1233, tixPool="b";
insert into tickets set shoId = 67, tixCode= 550, tixPool="b";
insert into tickets set shoId = 67, tixCode=1440, tixPool="b";
insert into tickets set shoId = 67, tixCode=9962, tixPool="b";
insert into tickets set shoId = 67, tixCode=8672, tixPool="b";
insert into tickets set shoId = 67, tixCode=2344, tixPool="b";

insert into tickets set shoId = 67, tixCode=2222, tixPool="w";
insert into tickets set shoId = 67, tixCode=2444, tixPool="w";
insert into tickets set shoId = 67, tixCode=9585, tixPool="w";
insert into tickets set shoId = 67, tixCode=8557, tixPool="w";
insert into tickets set shoId = 67, tixCode=4584, tixPool="w";
insert into tickets set shoId = 67, tixCode=2345, tixPool="w";
insert into tickets set shoId = 67, tixCode= 109, tixPool="w";
insert into tickets set shoId = 67, tixCode=4844, tixPool="w";
insert into tickets set shoId = 67, tixCode=1113, tixPool="w";
insert into tickets set shoId = 67, tixCode=2044, tixPool="w";

insert into tickets set shoId = 68, tixCode=4884, tixPool="b";
insert into tickets set shoId = 68, tixCode=8289, tixPool="b";
insert into tickets set shoId = 68, tixCode=1335, tixPool="b";
insert into tickets set shoId = 68, tixCode=5522, tixPool="b";
insert into tickets set shoId = 68, tixCode=   7, tixPool="b";
insert into tickets set shoId = 68, tixCode=1235, tixPool="b";
insert into tickets set shoId = 68, tixCode=1255, tixPool="b";
insert into tickets set shoId = 68, tixCode=3713, tixPool="b";
insert into tickets set shoId = 68, tixCode=7713, tixPool="b";
insert into tickets set shoId = 68, tixCode=6778, tixPool="b";

insert into tickets set shoId = 68, tixCode=1453, tixPool="w";
insert into tickets set shoId = 68, tixCode=1233, tixPool="w";
insert into tickets set shoId = 68, tixCode=2344, tixPool="w";
insert into tickets set shoId = 68, tixCode=1314, tixPool="w";
insert into tickets set shoId = 68, tixCode=9908, tixPool="w";
insert into tickets set shoId = 68, tixCode=0404, tixPool="w";
insert into tickets set shoId = 68, tixCode=2341, tixPool="w";
insert into tickets set shoId = 68, tixCode=5665, tixPool="w";
insert into tickets set shoId = 68, tixCode=3455, tixPool="w";
insert into tickets set shoId = 68, tixCode=4667, tixPool="w";

insert into tickets set shoId = 93, tixCode=4534, tixPool="b";
insert into tickets set shoId = 93, tixCode=8289, tixPool="b";
insert into tickets set shoId = 93, tixCode=1335, tixPool="b";
insert into tickets set shoId = 93, tixCode=5522, tixPool="b";
insert into tickets set shoId = 93, tixCode=   7, tixPool="b";
insert into tickets set shoId = 93, tixCode=1235, tixPool="b";
insert into tickets set shoId = 93, tixCode=1255, tixPool="b";
insert into tickets set shoId = 93, tixCode=3713, tixPool="b";
insert into tickets set shoId = 93, tixCode=7713, tixPool="b";
insert into tickets set shoId = 93, tixCode=6778, tixPool="b";
insert into tickets set shoId = 93, tixCode=4534, tixPool="b";
insert into tickets set shoId = 93, tixCode=8289, tixPool="b";
insert into tickets set shoId = 93, tixCode=1335, tixPool="b";
insert into tickets set shoId = 93, tixCode=5522, tixPool="b";
insert into tickets set shoId = 93, tixCode=   7, tixPool="b";
insert into tickets set shoId = 93, tixCode=1235, tixPool="b";
insert into tickets set shoId = 93, tixCode=1255, tixPool="b";
insert into tickets set shoId = 93, tixCode=3713, tixPool="b";
insert into tickets set shoId = 93, tixCode=7713, tixPool="b";
insert into tickets set shoId = 93, tixCode=6778, tixPool="b";

insert into tickets set shoId = 94, tixCode=4534, tixPool="b";
insert into tickets set shoId = 94, tixCode=8289, tixPool="b";
insert into tickets set shoId = 94, tixCode=1335, tixPool="b";
insert into tickets set shoId = 94, tixCode=5522, tixPool="b";
insert into tickets set shoId = 94, tixCode=   7, tixPool="b";
insert into tickets set shoId = 94, tixCode=1235, tixPool="b";
insert into tickets set shoId = 94, tixCode=1255, tixPool="b";
insert into tickets set shoId = 94, tixCode=3713, tixPool="b";
insert into tickets set shoId = 94, tixCode=7713, tixPool="b";
insert into tickets set shoId = 94, tixCode=6778, tixPool="b";
insert into tickets set shoId = 94, tixCode=4534, tixPool="b";
insert into tickets set shoId = 94, tixCode=8289, tixPool="b";
insert into tickets set shoId = 94, tixCode=1335, tixPool="b";
insert into tickets set shoId = 94, tixCode=5522, tixPool="b";
insert into tickets set shoId = 94, tixCode=   7, tixPool="b";
insert into tickets set shoId = 94, tixCode=1235, tixPool="b";
insert into tickets set shoId = 94, tixCode=1255, tixPool="b";
insert into tickets set shoId = 94, tixCode=3713, tixPool="b";
insert into tickets set shoId = 94, tixCode=7713, tixPool="b";
insert into tickets set shoId = 94, tixCode=6778, tixPool="b";

#
# Dummy transactions - web - 2000 series
#

# web, one REG
insert into charges set trnid=2001,
    chgId=1,
    chgType="Charge",
    chgDuplicateMode=true,
    chgRequestAmount=1500,
    chgAmount=1500,
    chgApprovalCode="000013",
    chgBatchNum="000104",
    chgCardType="Mastercard",
    chgCommercialCardResponseCode="X",
    chgExpDate="1212",
    chgMaskedAcctNum="XXXXXXXXXXXX1234",
    chgProcessorResponse="OK",
    chgResponseCode=0,
    chgTransactionID="000000000001",
    chgAcctNumSource=" ",
    chgAcctNumHash="0123456789ABCDEF0123456789ABCDEF",
    chgComment="Test data inserted by script";
insert into sales set trnId=2001, salType='prd', salName="Regular Admission",
    salCost=1500, salPaid=1500, salIsTicket=true, salIsTimed=true, 
    salPickupCount=1, salQuantity=1;
insert into transactions set trnId=2001,
    trnPhase='z', trnUser='testdata', trnMod='script',
    trnStation='W', trnPickupCode=123456789, trnRemoteAddr='255.0.0.13',
    trnEmail='test@hauntix.bix', trnNote='inserted by test loader';
update tickets set salId=1, tixState="Sold" where tixId=31;

# web, two REG, one VIP
insert into charges set trnid=2011,
    chgId=11,
    chgType="Charge",
    chgDuplicateMode=true,
    chgRequestAmount=5000,
    chgAmount=5000,
    chgApprovalCode="000013",
    chgBatchNum="000104",
    chgCardType="Mastercard",
    chgCommercialCardResponseCode="X",
    chgExpDate="1212",
    chgMaskedAcctNum="XXXXXXXXXXXX1234",
    chgProcessorResponse="OK",
    chgResponseCode=0,
    chgTransactionID="000000000047",
    chgAcctNumSource=" ",
    chgAcctNumHash="0123456789ABCDEF0123456789ABCDEF",
    chgComment="Test data inserted by script";
insert into sales set trnId=2011, salType='prd', salName="Regular Admission",
    salCost=1500, salPaid=1500, salIsTicket=true, salIsTimed=true, 
    salPickupCount=1, salQuantity=2;
insert into sales set trnId=2011, salType='prd', salName="VIP Admission",
    salCost=2000, salPaid=2000, salIsTicket=true, salIsTimed=true, 
    salPickupCount=1,salQuantity=1;
insert into transactions set trnId=2011,
    trnPhase='z', trnUser='testdata', trnMod='script',
    trnStation='W', trnPickupCode=123456789, trnRemoteAddr='255.0.0.13',
    trnEmail='test@hauntix.bix', trnNote='inserted by test loader';
update tickets set salId=1, tixState="Sold" where tixId=11;
update tickets set salId=1, tixState="Sold" where tixId=12;
update tickets set salId=2, tixState="Sold" where tixId=31;

# web, four REG
insert into charges set trnid=2012,
    chgId=12,
    chgType="Charge",
    chgDuplicateMode=true,
    chgRequestAmount=6000,
    chgAmount=6000,
    chgApprovalCode="000017",
    chgBatchNum="000104",
    chgCardType="Mastercard",
    chgCommercialCardResponseCode="Y",
    chgExpDate="1111",
    chgMaskedAcctNum="XXXXXXXXXXXX5678",
    chgProcessorResponse="OK",
    chgResponseCode=0,
    chgTransactionID="000000000048",
    chgAcctNumSource=" ",
    chgAcctNumHash="ABC0123456789ABCDEF0123456789ABC",
    chgComment="Test data inserted by script";
insert into sales set trnId=2012, salType='prd', salName="Regular Admission",
    salCost=1500, salPaid=1500, salIsTicket=true, salIsTimed=true, 
    salPickupCount=1,salQuantity=4;
insert into transactions set trnId=2012,
    trnPhase='z',trnUser='testdata',trnMod='script',
    trnStation='W',trnPickupCode=998877665,trnRemoteAddr='255.0.0.17',
    trnEmail='bogus@hauntix.bix',trnNote='inserted by test loader';
update tickets set salId=3,tixState="Sold" where tixId=13;
update tickets set salId=3,tixState="Sold" where tixId=14;
update tickets set salId=3,tixState="Sold" where tixId=15;
update tickets set salId=3,tixState="Sold" where tixId=16;


