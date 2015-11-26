drop database if exists hauntix;
create database hauntix;
use hauntix;

# Configuration data:  name-value pairs
create table config (
    cfgName varchar(16) not null unique,
    cfgValue varchar(64) null
    ) ENGINE=InnoDB;

# Represents products we sell - think of it as buttons on the cash register
create table products (
    prdId int not null unique auto_increment primary key,
    prdName varchar(32) not null comment "Name of the product",
    prdCost int not null default 100 comment "Product cost in cents",
    prdScreenPosition int unique null comment "Display position on POS screen;null=no-show",
    prdWebVisible boolean default false comment "Visible for sale on the web?",
    prdIsTaxable boolean default false comment "Taxable item?",
    prdIsTicket boolean default false comment "Issues a ticket?",
    prdIsTimed boolean default false comment "Is this for a timed event?",
    prdIsDaily boolean default false comment "Is this for a daily event?",
    prdIsNextAvail boolean default false comment "Is this button for the next available show?",
    prdClass varchar(8) comment "Product class (for discount, ticket, etc)"
    ) ENGINE=InnoDB;

# Defines product upgrades
create table upgrades (
    upgName varchar(32) not null unique comment "Name of this upgrade",
    upgFromPrdId int not null comment "ID of old product being upgraded",
    upgToPrdId int not null comment "ID of new product resulting from this upgrade",
    upgCost int null comment "Cost of upgrade; if Null is diff in old vs new prdCost",
    upgScreenPosition int unique null comment "Display position on POS screen"
    ) ENGINE=InnoDB;

# Discounts and coupons
create table discounts (
    dscName varchar(32) not null unique comment "Name of coupon or discount",
    dscMethod enum ("FixedAmount", "Percent", "ThresholdAmount"),
    dscAmount int not null comment "Cents off or hundredths of percent off",
    dscApplyToAll boolean default false 
        comment "Apply this discount to the whole transaction?", # If percent its %-off subtotal; if fixed its foreach product in the class
    dscMinProducts int null comment "Minimum number of products in the class that are needed for this discount to apply",
    dscClass varchar(8) null comment "Discount class",
    dscScreenPosition int unique null comment "Display position on POS screen"
    ) ENGINE=InnoDB;

# Transactions: sales plus payment and tax info
create table transactions (
    trnId int not null primary key auto_increment,
    trnTimestamp timestamp default now(),
    trnPhase char(1) comment "Disposition phase: new, open, pay, final or x-cancelled, void",
    trnUser varchar(32) comment "cashier who did this transaction",
    trnMod varchar(32) comment "manager on duty",
    trnStation char(1) comment "Station ID",
    trnCashAmount int not null default 0 comment "Cash amount, unit:cents",
    trnCheckAmount int not null default 0 comment "Check amount, unit:cents",
    trnCheckInfo varchar(24) comment "Check holder name and check number or other info",
    trnTaxAmount int not null default 0 comment "Sales tax paid on the transaction, units:cents",
    trnTaxRate decimal(7,6) default 0 comment "Tax rate in effect, 0.074000 = 7.4%",
    trnServiceCharge int not null default 0 comment "Service charge on the transaction, units:cents",
    trnPickupCode int unsigned null comment "Pickup code for the items in this transaction",
    trnRemoteAddr varchar(16) comment "IP address of customer for web",
    trnEmail varchar(255) comment "Email address of customer for web",
    trnNote varchar(255) comment "Special note associated with this transaction"
    ) ENGINE=InnoDB;

# Credit/debit card charges done as part of a transaction
create table charges (
    trnId int comment "Transaction ID in transactions table",
    chgId int not null primary key auto_increment,
    chgTimestamp timestamp default now(),
    chgType enum ("Charge", "Refund", "Void"),
    chgDuplicateMode boolean comment "Is duplicate checking enabled?",
    chgRequestAmount int comment "Amount requested to be charged, in cents",
    chgAmount int comment "Amount charged, in cents",
    chgApprovalCode varchar(6),
    chgBatchNum varchar(6),
    chgCardType varchar(16),
    chgCommercialCardResponseCode char(1) default " ",
    chgExpDate char(4),
    chgMaskedAcctNum varchar(24),
    chgProcessorResponse varchar(32),
    chgResponseCode int,
    chgTransactionID char(12),
    chgAcctNumSource varchar(16),
    chgAcctNumHash char(32) comment "MD5 hash of card account number",
    chgComment varchar(255)
    ) ENGINE=InnoDB;

# Records items sold as part of a transaction
create table sales (
    trnId int comment "Transaction ID in transactions table",
    salId int not null unique auto_increment primary key comment "ID for this record",
    salType char(3) comment "type code: prd, dsc, upg, ...",
    salName varchar(32) not null comment "Item name - product, discount, or upgrade",
    salQuantity int not null default 1 comment "Number of this product sold at this price",
    salCost int not null comment "cost per-item, units: cents",
    salPaid int not null comment "actual amt paid per-item, after discounts, unit: cents",
    salIsTaxable boolean default false comment "item is taxed?",
    salIsTicket boolean default false comment "is the item a ticket?",
    salIsTimed boolean default false comment "is this for a timed event?",
    salIsDaily boolean default false comment "is this for a daily event?",
    salPickupCount int default 0 comment "Count of pickups done on this item"
    ) ENGINE=InnoDB;

# Represents tickets
create table tickets (
    tixId int not null unique auto_increment primary key comment "Ticket ID",
    salId int comment "Related sale for this ticket",
    shoId int comment "Related show for this ticket",
    tixCode int comment "Entropy code",
    tixPool char(1) comment "To which pool is this ticket allocated? (web, booth, etc...)",
    tixState enum ("Idle", "Held", "Sold", "Used", "Void", "Swap") default "Idle" comment "State of this ticket",
    tixHoldUntil timestamp default 0 comment "When does the hold expire?",
    tixIsPreprinted boolean default false comment "Is this a preprinted ticket?",
    tixAnyCostSwap boolean default false comment "Ticket may be swapped with any cost level",
    tixAnyDateSwap boolean default false comment "Ticket may be swapped regardless of show date",
    tixNote varchar(255) comment "Special note associated with this ticket"
    ) ENGINE=InnoDB;

# Defines shows, show time, prices, etc
#   Note: shoName must match a prdName for it to be sellable
### TODO: 
###   Add shoDone timestamp for when the show ends, ticket will be invalid after then
###   Add shoGoesOnSale or shoSellAfter timestamp - show not available for selling until this time
###   Add shoHidden boolean to hide shows
create table shows (
    shoId int not null unique auto_increment primary key,
    shoTime timestamp default 0 comment "When show starts",
    shoSellUntil timestamp null default NULL comment "When to stop selling the show; NULL=no end",
    shoClass varchar(8) comment "Class of show: REG, VIP, etc",
    shoCost int not null default 0 comment "unit: cents; Normal cost of this class of show on this date & time",
    shoName varchar(32) comment "Name of this show; must match a prdName"
    ) ENGINE=InnoDB;

# Attempted event entry records - when a customer is scanned into the event
create table scans (
    scnId int not null unique auto_increment primary key comment "Scan ID",
    scnTimestamp timestamp default now(),
    scnNumber varchar(16) not null comment "Scanned ticket number - may NOT be a valid ticket so not an fk",
    scnStatus varchar(32) comment "Textual status",
    scnResult enum ("Allowed", "Denied", "ForceAllow", "ForceDeny"),
    scnUser varchar(32) comment "User agent who did the scan"
    ) ENGINE=InnoDB;

# Pickup Code Uses
create table pickups (
    pikId int not null unique auto_increment primary key comment "Pickup record ID",
    pikTimestamp timestamp default now() comment "When the pickup was tried",
    pikCode varchar(31) comment "The pickup code attempted",
    pikEmail varchar(255) comment "The email address used on the pickup",
    pikRemoteAddr varchar(16) comment "IP address of customer trying this, if web",
    pikResult varchar(255) comment "Result (error) of attempt"
    ) ENGINE=InnoDB;


create table badgeuse (
    busTimestamp timestamp default now(),
    busBadge varchar(32),
    busQuantity int unsigned not null default 0
    ) ENGINE=InnoDB;

# Configs - these should be in the server config file!
ALTER TABLE transactions AUTO_INCREMENT = 1301; # Pick something!
#SET GLOBAL server_id=3;                 # Use station number where the server is at
#SET GLOBAL auto_increment_increment=7;  # Must be at least the number of stations, and then some
#SET GLOBAL auto_increment_offset=3;     # Use station number

# Initial setup
drop user 'hauntix'@'localhost';
drop user 'hauntix'@'%';
create user 'hauntix'@'localhost' identified by "some.password.goes.here";
create user 'hauntix'@'%' identified by "some.password.goes.here";
grant all on hauntix.* to 'hauntix'@'localhost';
grant all on hauntix.* to 'hauntix'@'%';
