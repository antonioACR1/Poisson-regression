#First I will create my database and table in MySQL

##SHOW DATABASES;
##CREATE DATABASE sales2;
##CREATE TABLE sales (Date date, Month varchar(1000), Year int, CustomerID int,	CustomerAge int, AgeGroup varchar(1000), CustomerGender varchar(1000), Country varchar(1000), State varchar(1000), ProductCategory varchar(1000), SubCategory varchar(1000), Product varchar(1000), FrameSize int, OrderQuantity int,	UnitCost int, UnitPrice int, Cost int, Revenue int, Profit int);
##USE sales2;
##SHOW TABLES;

#Now I will connect MySQL to R

install.packages("RMySQL")
library(RMySQL)
mydb <- dbConnect(MySQL(), user='*****', password='*****', dbname='sales2', host='localhost')

#View the column names of my created table in R
dbListFields(mydb,'sales')

#the following is VBA code to copy my .CSV table to another table in Excel

##Sub copiar2()
##i = 1
##Do While i <= 113037
##For j=1 To 19
##Application.Workbooks("Libro1").Worksheets("Hoja1").Cells(i, j).Value = Application.Workbooks("Lab8Start v5").Worksheets("Data").Cells(i, j).Value
##Next j
##i = i + 1
##Loop
##End Sub

#read the .CSV file in R
df <- read.csv(file="~/sales.csv", sep=";",header=TRUE)

#have a look
head(df)
summary(df)


#the following steps are to insert my data into MySQL from R

#Step 1: check types
str(df)

#Step 2: convert factors to strings
df$Date <- as.character(df$Date)
df$Month <- as.character(df$Month)
df$Age.Group <- as.character(df$Age.Group)
df$Customer.Gender <- as.character(df$Customer.Gender)
df$Country <- as.character(df$Country)
df$State <- as.character(df$State)
df$Product.Category <- as.character(df$Product.Category)
df$Sub.Category <- as.character(df$Sub.Category)
df$Product <- as.character(df$Product)


#The date format in MySQL is %Y/%m/%d but the column 'Date' (as string) in my table 'sales' has the format %d/%m/%Y.
#Therefore, I will split 'Date' and then paste the day,month and year so that it coincides with the date format of MySQL.

#Step 3: Split first and then convert to dataframe
df$Date
y<-as.data.frame(strsplit(df[1:113036,1],"/"))
head(y)
#Step 4: Transpose
y1<-t(y)
head(y1)
str(y1)

#Step 5: Now paste all these elements with the required order and insert them into MySQL together with the other columns

for(i in 1:1000){d1<-paste(y1[i,3],"/",y1[i,2],"/",y1[i,1],sep="") 
dbGetQuery(mydb,paste("INSERT INTO sales (Date, Month, Year, CustomerID, CustomerAge, AgeGroup, CustomerGender, Country, State, ProductCategory, SubCategory, Product, OrderQuantity, UnitCost, UnitPrice, Cost, Revenue, Profit) VALUES ('",d1,"','",df[i,2],"',",df[i,3],",",df[i,4],",",df[i,5],",'",df[i,6],"','",df[i,7],"','",df[i,8],"','",df[i,9],"','",df[i,10],"','",df[i,11],"','",df[i,12],"',",df[i,14],",",df[i,15],",",df[i,16],",",df[i,17],",",df[i,18],",",df[i,19],")"))
}

#Now the objective is to know if there is a significant relation between
#the age of a customer and the mean of the number of units bought by the costumer
#during 2009 

#Now I select the sum of units for each customer during 2009 and the age of each customer, and this information grouped by customerID  
df2<-dbGetQuery(mydb,paste("SELECT CustomerID,CustomerAge, SUM(OrderQuantity) AS 'Sum.of.Units.Ordered.by.Customer' FROM sales GROUP BY CustomerID WHERE Date BETWEEN '2009/01/01' AND '2009/12/31'"))
df2

#I will choose a random sample of size 30, then I will assume that this sample corresponds to a simple random sampling extracted from the population
df1 <- df2[sample(nrow(df2),size=30,replace=FALSE,prob=NULL),]
df1
str(df1)

#Now let's use glm()
model <- glm(Sum.of.Units.Ordered.by.Customer~CustomerAge, data=df1, family=poisson)

#The null hypothesis is H_0: beta_1 = 0, in other words the slope is equal to zero.
#If the slope is zero, then there is no relation between the mean of units bought by the customer and his/her age

#let's find out the p-value
summary(model)

#the p-value is 0.0135, less than 0.05, so we reject the null hypothesis
#Therefore, there is a significant relationship between the mean of units bought by a customer and the customer's age
#The age has an important impact on the mean of units bought by customers


