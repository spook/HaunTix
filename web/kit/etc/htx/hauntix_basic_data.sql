# Test data for the hauntix database; simple show setup
use hauntix;

insert into config set
  cfgName = "htx.version",
  cfgValue = "0.2";

insert into config set
  cfgName = "tax.rate",
  cfgValue = "0.039";

insert into products set
  prdName = "Regular Admission",
  prdClass = "REG",
  prdCost = 1500,
  prdIsTicket = true,
  prdWebVisible = true,
  prdScreenPosition = 2;

insert into products set
  prdName = "VIP Admission",
  prdClass = "VIP",
  prdCost = 2000,
  prdIsTicket = true,
  prdWebVisible = true,
  prdScreenPosition = 5;

insert into products set
  prdName = "VIP Upgrade",
  prdCost = 500,
  prdClass = "VIP",
  prdIsTicket = true,
  prdWebVisible = false,
  prdScreenPosition = 11;


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


insert into discounts set
  dscName = "Group Discount",
  dscMethod = "FixedAmount",
  dscAmount = 500,
  dscScreenPosition = 17;


#  AnyDay shows
insert into shows set shoTime = "2011-09-30 19:30:00", shoClass = "REG", shoName="Regular Admission", shoCost = 1500, shoSellUntil = "947:20:00", shoId=1;
insert into shows set shoTime = "2011-09-30 19:30:00", shoClass = "VIP", shoName="VIP Admission", shoCost = 2000, shoSellUntil = "947:20:00", shoId=2;

# Insert some starter GA tickets.  Use htx-mktix to generate tickets for real.
# 10 each of regular and VIP for booth and web.
insert into tickets set shoId = 1, tixCode=2412, tixPool="b";
insert into tickets set shoId = 1, tixCode=4556, tixPool="b";
insert into tickets set shoId = 1, tixCode=3613, tixPool="b";
insert into tickets set shoId = 1, tixCode=5713, tixPool="b";
insert into tickets set shoId = 1, tixCode=6833, tixPool="b";
insert into tickets set shoId = 1, tixCode=7950, tixPool="b";
insert into tickets set shoId = 1, tixCode=8040, tixPool="b";
insert into tickets set shoId = 1, tixCode= 862, tixPool="b";
insert into tickets set shoId = 1, tixCode=9772, tixPool="b";
insert into tickets set shoId = 1, tixCode=1644, tixPool="b";

insert into tickets set shoId = 1, tixCode=3522, tixPool="w";
insert into tickets set shoId = 1, tixCode=4444, tixPool="w";
insert into tickets set shoId = 1, tixCode=5385, tixPool="w";
insert into tickets set shoId = 1, tixCode=6257, tixPool="w";
insert into tickets set shoId = 1, tixCode=7184, tixPool="w";
insert into tickets set shoId = 1, tixCode=8045, tixPool="w";
insert into tickets set shoId = 1, tixCode=9259, tixPool="w";
insert into tickets set shoId = 1, tixCode=  44, tixPool="w";
insert into tickets set shoId = 1, tixCode=2313, tixPool="w";
insert into tickets set shoId = 1, tixCode=1444, tixPool="w";


insert into tickets set shoId = 2, tixCode=4572, tixPool="b";
insert into tickets set shoId = 2, tixCode=5657, tixPool="b";
insert into tickets set shoId = 2, tixCode=6713, tixPool="b";
insert into tickets set shoId = 2, tixCode=7813, tixPool="b";
insert into tickets set shoId = 2, tixCode=8923, tixPool="b";
insert into tickets set shoId = 2, tixCode=9020, tixPool="b";
insert into tickets set shoId = 2, tixCode=  40, tixPool="b";
insert into tickets set shoId = 2, tixCode=8262, tixPool="b";
insert into tickets set shoId = 2, tixCode=9352, tixPool="b";
insert into tickets set shoId = 2, tixCode=6444, tixPool="b";

insert into tickets set shoId = 2, tixCode=5522, tixPool="w";
insert into tickets set shoId = 2, tixCode=6614, tixPool="w";
insert into tickets set shoId = 2, tixCode=3785, tixPool="w";
insert into tickets set shoId = 2, tixCode=2827, tixPool="w";
insert into tickets set shoId = 2, tixCode=1984, tixPool="w";
insert into tickets set shoId = 2, tixCode= 165, tixPool="w";
insert into tickets set shoId = 2, tixCode=2209, tixPool="w";
insert into tickets set shoId = 2, tixCode=3334, tixPool="w";
insert into tickets set shoId = 2, tixCode=4433, tixPool="w";
insert into tickets set shoId = 2, tixCode=5544, tixPool="w";

