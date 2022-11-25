# nyc_motor_vehicle_accidents
https://data.cityofnewyork.us/Public-Safety/Motor-Vehicle-Collisions-Crashes/h9gi-nx95
Collected Nov 13

### Table of Contents
[Introduction](#introduction)
[Exploratory Data Analysis Process](#exploratorydataanalysisprocess)

## Introduction
I live in Hoboken, NJ right across the Hudson River from NYC. I have worked in the city and frequently go in for pleasure. My old boss frequently warned our team of the dangerous of driving in the city and to always be on the lookout for distracted drivers due to the high number of motor vehicle incidents.

While I don't doubt that NYC has a high number of vehicle incidents, I wanted to use publically available data to find out what factors caused the most unsafe conditions. This is a personal Exploratory Data Analysis of Motor Vehicle Collisions in  New York City from November 2012 - Novemeber 2022.

## Exploratory Data Analysis Process
## Ask
#### Guiding Questions
- What are the highest risk times for an accident?
- Where do the most accidents occur?
- What are the most frequently involved vehicles?
- Who is more at risk? Pedestrians, passengers, etc.
- Is there anything I can change about how and when I travel in NYC to have a better chance of a safer experience?

Using these questions, I'll be exploring the data and concluding my findings.
 
 
 
## Data Cleaning
Messy Strings
For CONTRIBUTING_FACTOR_VEHICLE_1:
Illness	2088
Illnes	1440
cleaned to make them all illness

95 instances of "80" and 10 instances of "1". Changed to unspecified

Reduced different groups of contributing factors
initially, there were 59 different kinds of contributing factors
Changes made:
Unspecified: Added 80, 1
Driver Distracted: Driver Inattention/Distraction, 
