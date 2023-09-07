/*BRYANAIR - Elly Sjölund ellsj457, Rickard Peters ricpe737*/ 

SET FOREIGN_KEY_CHECKS=0; -- to disable them

DROP TABLE IF EXISTS day;
DROP TABLE IF EXISTS flight;
DROP TABLE IF EXISTS reservation;
DROP TABLE IF EXISTS contact;
DROP TABLE IF EXISTS payment;
DROP TABLE IF EXISTS creditcard;
DROP TABLE IF EXISTS passenger;
DROP TABLE IF EXISTS booking;
DROP TABLE IF EXISTS route;
DROP TABLE IF EXISTS airport;
DROP TABLE IF EXISTS year;
DROP TABLE IF EXISTS weeklySchedule;
DROP VIEW IF EXISTS allFlights;

DROP PROCEDURE IF EXISTS addYear;
DROP PROCEDURE IF EXISTS addDay;
DROP PROCEDURE IF EXISTS addDestination;
DROP PROCEDURE IF EXISTS addRoute;
DROP PROCEDURE IF EXISTS addFlight;
DROP PROCEDURE IF EXISTS addReservation; 
DROP PROCEDURE IF EXISTS addPassenger;
DROP PROCEDURE IF EXISTS addContact;
DROP PROCEDURE IF EXISTS addPayment;
DROP FUNCTION IF EXISTS calculateFreeSeats;
DROP FUNCTION IF EXISTS calculatePrice;


CREATE TABLE airport (
    airport_id VARCHAR(3),
    airportName VARCHAR(30),
    country VARCHAR(30),
    CONSTRAINT airport PRIMARY KEY (airport_id)
);

CREATE TABLE route (
    route_id INTEGER AUTO_INCREMENT,
    departs_from VARCHAR(3),
    arrives_to VARCHAR(3),
    year INTEGER,
    routePrice DOUBLE,
    CONSTRAINT con_routId PRIMARY KEY (route_id)
);

CREATE TABLE year (
    currentYear INTEGER,
    profitFactor DOUBLE,
    CONSTRAINT years PRIMARY KEY (currentYear)
) ;

CREATE TABLE day (
    dayCurrentYear INTEGER,
    day VARCHAR(10),
    weekdayFactor DOUBLE,
    CONSTRAINT days PRIMARY KEY (day)
);

CREATE TABLE weeklySchedule (
    weekNumber INTEGER AUTO_INCREMENT,
    route INTEGER,
    departureTime TIME,
    day VARCHAR(10),
    year INTEGER,
    PRIMARY KEY (weekNumber)
);
 
CREATE TABLE flight (
    flightNumber INTEGER AUTO_INCREMENT,
    week INTEGER,
    weeklyScheduleId INTEGER,
    PRIMARY KEY (flightNumber)
);

CREATE TABLE reservation (
    reservationNumber INTEGER AUTO_INCREMENT,
    flight INTEGER,
    contact INTEGER,
    numberOfPassengers INTEGER,
    passportNumber INTEGER,
    CONSTRAINT con_reservationNr PRIMARY KEY (reservationNumber)
);

CREATE TABLE passenger (
    ticketNumber INTEGER,
    passportNumber INTEGER,
    passengerName VARCHAR(30),
    reservationNumber INTEGER,
    CONSTRAINT passenger_passportNumber PRIMARY KEY (passportNumber)
);

CREATE TABLE contact (
    passportNumber INTEGER,
    contactReservationNumber INTEGER,
    phoneNumber BIGINT,
    email VARCHAR(30),
    PRIMARY KEY (passportNumber)
);
  
CREATE TABLE booking ( /* jätteosäker på hur den här ska vara med isBooking på reservations!? */
	bookingNumber INTEGER,
    ticketNumber INTEGER,
    price DOUBLE,
    cardNumber BIGINT,
    PRIMARY KEY (bookingNumber)
	); 
   
CREATE TABLE creditcard (
	cardNumber BIGINT,
	cardName VARCHAR(30),
    PRIMARY KEY (cardNumber)
	); 
    
CREATE TABLE payment (
	payment_id VARCHAR(3),
    bookingID INTEGER,
    cardNumber BIGINT,
    PRIMARY KEY (payment_id)
    ); 

#----------------- Foreign keys       --------------------

-- SET FOREIGN_KEY_CHECKS=1; -- to disable them

ALTER TABLE route ADD CONSTRAINT route_depart FOREIGN KEY (departs_from) REFERENCES airport(airport_id) ON DELETE CASCADE; 
ALTER TABLE route ADD CONSTRAINT route_arrive FOREIGN KEY (arrives_to) REFERENCES airport(airport_id) ON DELETE CASCADE;
ALTER TABLE route ADD CONSTRAINT route_year FOREIGN KEY (year) REFERENCES year(currentYear) ON DELETE CASCADE; 
ALTER TABLE day ADD CONSTRAINT day_year FOREIGN KEY (dayCurrentYear) REFERENCES year(currentYear) ON DELETE CASCADE; 
ALTER TABLE weeklySchedule ADD CONSTRAINT weeklySchedule_year FOREIGN KEY (year) REFERENCES year(currentYear) ON DELETE CASCADE; 
ALTER TABLE weeklySchedule ADD CONSTRAINT weeklySchedule_id FOREIGN KEY (route) REFERENCES route(route_id) ON DELETE CASCADE; 
ALTER TABLE flight ADD CONSTRAINT flight_sheduleId FOREIGN KEY (weeklyScheduleId) REFERENCES weeklySchedule(weekNumber) ON DELETE CASCADE; 
ALTER TABLE reservation ADD CONSTRAINT reservation_flight FOREIGN KEY (flight) REFERENCES flight(flightNumber) ON DELETE CASCADE; 
-- ALTER TABLE reservation ADD CONSTRAINT reservation_contact FOREIGN KEY (contactReference) REFERENCES contact(ticketNumber) ON DELETE CASCADE; 
-- ALTER TABLE reservation ADD CONSTRAINT reservation_isBooking FOREIGN KEY (isBooking) REFERENCES booking(bookingNumber) ON DELETE CASCADE; 
ALTER TABLE passenger ADD CONSTRAINT passenger_reservation FOREIGN KEY (reservationNumber) REFERENCES reservation(reservationNumber) ON DELETE CASCADE; 
ALTER TABLE contact ADD CONSTRAINT contact_passportNumber FOREIGN KEY (passportNumber) REFERENCES passenger(passportNumber)ON DELETE CASCADE; 
ALTER TABLE payment ADD CONSTRAINT payment_bookingId FOREIGN KEY (bookingId) REFERENCES booking(bookingNumber) ON DELETE CASCADE; 
ALTER TABLE payment ADD CONSTRAINT payment_cardNumber FOREIGN KEY (cardNumber) REFERENCES creditcard(cardNumber) ON DELETE CASCADE	; 


# ----------------      Procedures      -----------------

DELIMITER // 
CREATE PROCEDURE addYear(IN year INT, IN profitFactor DOUBLE) 
BEGIN
	INSERT INTO year VALUES (year, profitFactor);
END; //

CREATE PROCEDURE addDay(IN year_in INT, IN day_in VARCHAR(10), IN weekdayFactor DOUBLE) 
BEGIN
	INSERT INTO day VALUES (year_in, day_in, weekdayFactor);
END; //

CREATE PROCEDURE addDestination(IN airport_id VARCHAR(3), IN name VARCHAR(30), IN country VARCHAR(30))
BEGIN
	INSERT INTO airport VALUES (airport_id, name, country);
END; //


CREATE PROCEDURE addRoute(IN departs_from VARCHAR(3), IN arrives_to VARCHAR(3), IN year INT, IN routePrice DOUBLE)
BEGIN
	INSERT INTO route(departs_from, arrives_to, year, routePrice) VALUES (departs_from, arrives_to, year, routePrice);
END; //

CREATE PROCEDURE addFlight(IN departs_from_in VARCHAR(3), IN arrives_to_in VARCHAR(3),
 IN year_in INT, IN day_in VARCHAR(10), IN departure_time_in TIME) 


BEGIN
		DECLARE weekNumber_id INT; 
        DECLARE routeId INT; 
        DECLARE weeklySchedule_id INT; 
        SET weekNumber_id = 1; 
        
        SELECT route_id INTO routeId FROM route WHERE departs_from = departs_from_in AND arrives_to = arrives_to_in 
        AND year_in = year LIMIT 1;
        INSERT INTO weeklySchedule(route, departureTime, day, year) VALUES (routeId, departure_time_in, day_in, year_in);

		SELECT weekNumber INTO weeklySchedule_id FROM weeklySchedule WHERE departureTime = departure_time_in 
        AND day = day_in AND route = routeId; 
			WHILE weekNumber_id <= 52 DO 
					INSERT INTO flight(week, weeklyScheduleId) VALUES (weekNumber_id, weeklySchedule_id);
                    SET weekNumber_id = weekNumber_id + 1; 
			END WHILE; 
END; //

#---------------------------- Help functions ----------------------------

CREATE FUNCTION calculateFreeSeats(flightnumber_in INTEGER)
RETURNS INTEGER

BEGIN
DECLARE total_no_passengers INTEGER; 
SET total_no_passengers = 0; 
SELECT SUM(numberOfPassengers) INTO total_no_passengers FROM reservation, booking 
WHERE reservation.flight = flightnumber_in AND reservation.reservationNumber = booking.bookingNumber LIMIT 10;
IF total_no_passengers IS NULL THEN
	RETURN 40; 
ELSE 
	RETURN 40 - total_no_passengers; 
END IF; 
END; //

CREATE FUNCTION calculatePrice(flightnumber_in INTEGER)
RETURNS DOUBLE #routePrice är double
BEGIN

DECLARE route_price DOUBLE; 
DECLARE weekday_factor DOUBLE;
DECLARE booked_seats INTEGER;
DECLARE selected_day VARCHAR(10);
DECLARE profit_factor DOUBLE; 
DECLARE out_price DOUBLE; 
DECLARE year_temp INTEGER;

SET route_price = 0.0; 
SET weekday_factor = 0.0; 
SET booked_seats = 0; 
SET profit_factor = 0.0; 
SET out_price = 0.0; 

SELECT routePrice INTO route_price FROM flight, weeklySchedule, route WHERE route.route_id = weeklySchedule.route 
AND flightnumber_in = flight.flightNumber AND flight.weeklyScheduleId = weeklySchedule.weekNumber LIMIT 10; 

SELECT weeklySchedule.day INTO selected_day FROM weeklySchedule, flight WHERE flightnumber_in = flight.flightNumber 
AND weeklyScheduleId = weekNumber LIMIT 10;

SELECT weekdayFactor INTO weekday_factor FROM day WHERE selected_day = day; 
SELECT 40 - calculateFreeSeats(flightnumber_in) INTO booked_seats; 
SELECT year INTO year_temp FROM weeklySchedule WHERE year = year_temp;
SELECT profitFactor INTO profit_factor FROM year, day WHERE selected_day = day.day AND day.dayCurrentYear = currentYear LIMIT 10; 
SET out_price = route_price * weekday_factor * (booked_seats + 1) / 40 * profit_factor;
-- SELECT out_price AS 'Message';

RETURN ROUND(out_price, 3);
END; // 

CREATE TRIGGER ticket_no
BEFORE INSERT ON booking 
FOR EACH ROW SET NEW.ticketNumber = FLOOR(900000 + (RAND() * 100000));
//

CREATE PROCEDURE addReservation(IN departs_from_in VARCHAR(3), IN arrives_to_in VARCHAR(3), IN year_in INT, IN week_in VARCHAR(10),
IN day_in VARCHAR(10), IN time_in TIME, IN number_of_passengers_in INTEGER, OUT output_reservation_nr INTEGER)

BEGIN 
DECLARE flight_number INTEGER; 
DECLARE weeklySchedule_id INTEGER; 
DECLARE route_id_temp INTEGER; 

SET flight_number = 0; 
SET weeklySchedule_id = 0; 
SET route_id_temp = 0;

SELECT route_id INTO route_id_temp FROM route WHERE departs_from_in = departs_from 
AND arrives_to_in = arrives_to AND year = year_in LIMIT 10; 

SELECT weekNumber INTO weeklySchedule_id FROM weeklySchedule WHERE day = day_in 
AND route = route_id_temp AND departureTime = time_in; 

SELECT flightNumber INTO flight_number FROM flight WHERE weeklyScheduleId = weeklySchedule_id AND week = week_in; 

IF flight_number != 0 THEN
	IF calculateFreeSeats(flight_number) >= number_of_passengers_in THEN 
		SELECT (100000 * RAND() + 430000) INTO output_reservation_nr;
		INSERT INTO reservation(reservationNumber, numberOfPassengers, flight) VALUES (output_reservation_nr, number_of_passengers_in, flight_number);
	ELSE
		SELECT "There are not enough seats available on the chosen flight" AS 'Message'; 
	END IF; 
ELSE
	SELECT "There exist no flight for the given route, date and time" AS 'Message';
END IF;
END; //

CREATE PROCEDURE addPassenger(IN reservation_nr_in INTEGER, IN passport_nr_in INTEGER, IN name_in VARCHAR(30))
BEGIN
DECLARE passport_number INTEGER; 
DECLARE reservation_number INTEGER; 
DECLARE booking_number INTEGER; 

SELECT passportNumber INTO passport_number FROM passenger WHERE passportNumber = passport_nr_in; 
SELECT reservationNumber INTO reservation_number FROM reservation WHERE reservationNumber = reservation_nr_in; 
SELECT bookingNumber INTO booking_number FROM booking WHERE bookingNumber = reservation_nr_in; 

IF reservation_number IS NULL THEN
	SELECT "The given reservation number does not exist" AS 'Message'; 
ELSEIF (booking_number) IS NOT NULL THEN
	SELECT "The booking has already been payed, and no further passengers can be added" AS 'Message';
ELSE
	IF passport_number IS NULL THEN
		INSERT IGNORE INTO passenger(passportNumber, passengerName) VALUES (passport_nr_in, name_in); 
	END IF; 
    INSERT IGNORE INTO contact(passportNumber, contactReservationNumber) VALUES (passport_nr_in, reservation_number);
END IF; 
END;
//

CREATE PROCEDURE addContact(IN reservation_nr_in INTEGER,IN passport_nr_in INTEGER, IN email_in VARCHAR(30), IN phone_nr_in BIGINT)
BEGIN

DECLARE passport_nr INTEGER;
DECLARE reservation_nr INTEGER; 

SELECT reservationNumber INTO reservation_nr FROM reservation WHERE reservation_nr_in = reservationNumber; 
SELECT passportNumber INTO passport_nr FROM contact WHERE passport_nr_in = passportNumber; 

IF reservation_nr IS NULL THEN
	SELECT "The given reservation number does not exist!" AS 'Message'; 
ELSE 
	IF (EXISTS(SELECT * FROM passenger WHERE passport_nr_in = passportNumber)) THEN 
		INSERT IGNORE INTO contact(contactReservationNumber, phoneNumber, email) VALUES (reservation_nr_in, phone_nr_in, email_in);
		UPDATE reservation SET passportNumber = passport_nr_in WHERE (reservation_nr_in = reservationNumber);
    ELSE
		SELECT "The contact must also be a passenger." AS 'Message';
	END IF;
END IF;    
END;
//


CREATE PROCEDURE addPayment(IN reservation_nr_in INT, IN cardholder_name_in VARCHAR(30), IN credit_card_number_in BIGINT)
BEGIN
DECLARE temp_numberOfPassengers INT DEFAULT 0;
DECLARE temp_flight_number INT;

IF (EXISTS(SELECT reservationNumber FROM reservation WHERE reservation_nr_in = reservationNumber)) THEN 
	IF reservation_nr_in IN (SELECT passportNumber FROM contact WHERE contactReservationNumber) IS NOT NULL THEN
		SELECT numberOfPassengers INTO temp_numberOfPassengers FROM reservation WHERE reservationNumber = reservation_nr_in;
        SELECT flight INTO temp_flight_number FROM reservation WHERE reservationNumber = reservation_nr_in;
			IF calculateFreeSeats(temp_flight_number) >= temp_numberOfPassengers THEN
            SELECT SLEEP(5);
				IF (SELECT cardNumber FROM creditcard WHERE cardNumber = credit_card_number_in) IS NOT NULL THEN
					INSERT INTO creditcard(cardNumber ,cardName) VALUES (credit_card_number_in,cardholder_name_in);
                END IF;    
				
                INSERT INTO booking(bookingNumber,cardNumber) VALUES (reservation_nr_in,credit_card_number_in);
			ELSE 
				DELETE FROM reservation WHERE reservationNumber = reservation_nr_in;
                SELECT "Not enough free seats" AS 'Message';
			END IF;
    ELSE
		SELECT "Contact is missing from the reservation" AS 'Message';
    END IF;
ELSE
	SELECT "Reservation does not exist" AS 'Message';
END IF;
END;
 //

CREATE VIEW allFlights AS 
(SELECT a2.airportName departure_city_name, a1.airportName destination_city_name, w.departureTime departure_time,
w.day departure_day, f.week departure_week, w.year departure_year, calculateFreeSeats(f.flightNumber) nr_of_free_seats, 
calculatePrice(f.flightNumber) current_price_per_seat FROM flight f JOIN weeklySchedule w ON f.weeklyScheduleId = w.weekNumber
JOIN route r ON w.route = r.route_id
JOIN airport a1 ON r.arrives_to = a1.airport_id
JOIN airport a2 ON r.departs_from = a2.airport_id); 