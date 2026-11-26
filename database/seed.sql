--
-- PostgreSQL database dump
--

\restrict QBeorOy4E4stz64aGoBSqeLx6NOJQyXad1kMFcsbRkgRXGH3vdtUyjVqiFZvLVz

-- Dumped from database version 17.12
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: properties; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (1, 'Business Bay Studio', 'Business Bay', 'apartment', 0, 620000.00, 42.00, 'Compact investment property', 'available', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (2, 'Business Bay Premium', 'Business Bay', 'apartment', 2, 1400000.00, 105.00, 'Canal view and modern interior', 'available', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (3, 'Downtown Penthouse', 'Downtown Dubai', 'penthouse', 4, 9500000.00, 380.00, 'Luxury penthouse with panoramic views', 'available', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (4, 'Dubai Hills Townhouse', 'Dubai Hills', 'townhouse', 3, 3200000.00, 220.00, 'Family home with private garden', 'available', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (5, 'Dubai Hills Apartment', 'Dubai Hills', 'apartment', 2, 1650000.00, 118.00, 'Golf community and green spaces', 'available', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (6, 'Marina Luxury Residence', 'Dubai Marina', 'apartment', 2, 1800000.00, 135.00, 'Furnished apartment with marina view', 'available', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (7, 'JVC Modern Studio', 'Jumeirah Village Circle', 'apartment', 0, 480000.00, 39.00, 'Affordable studio for investment', 'available', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (8, 'Palm Luxury Villa', 'Palm Jumeirah', 'villa', 4, 8500000.00, 420.00, 'Private pool and beach access', 'available', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (9, 'Marina Waterfront Apartment', 'Dubai Marina', 'apartment', 2, 1300000.00, 105.00, 'Waterfront apartment with balcony', 'sold', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (10, 'Downtown Central Studio', 'Downtown Dubai', 'apartment', 0, 1100000.00, 52.00, 'Studio near Dubai Mall', 'available', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (11, 'Marina View Apartment', 'Dubai Marina', 'apartment', 2, 1450000.00, 112.00, 'Sea view, balcony, gym and pool', 'available', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (12, 'Marina Executive Apartment', 'Dubai Marina', 'apartment', 3, 2400000.00, 170.00, 'Premium apartment with sea view', 'available', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (13, 'JVC Garden Apartment', 'Jumeirah Village Circle', 'apartment', 1, 780000.00, 73.00, 'Garden view and swimming pool', 'available', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (14, 'Business Bay Residence', 'Business Bay', 'apartment', 1, 950000.00, 78.00, 'Modern apartment near business district', 'available', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (15, 'Palm Signature Villa', 'Palm Jumeirah', 'villa', 5, 15000000.00, 650.00, 'Luxury beachfront villa', 'reserved', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (16, 'JVC Family Apartment', 'Jumeirah Village Circle', 'apartment', 2, 1100000.00, 110.00, 'Family friendly community with parking', 'available', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (17, 'Palm Beach Apartment', 'Palm Jumeirah', 'apartment', 2, 3200000.00, 145.00, 'Private beach and sea view', 'available', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (18, 'Marina Studio', 'Dubai Marina', 'apartment', 0, 750000.00, 45.00, 'Studio near metro station', 'available', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (19, 'Dubai Hills Family Villa', 'Dubai Hills', 'villa', 4, 5400000.00, 350.00, 'Modern villa with private garden', 'available', '2026-11-25 10:06:31.928447+00');
INSERT INTO public.properties (id, title, location, property_type, bedrooms, price, area_sqm, description, status, created_at) OVERRIDING SYSTEM VALUE VALUES (20, 'Downtown Skyline', 'Downtown Dubai', 'apartment', 2, 2100000.00, 125.00, 'Burj Khalifa view and luxury amenities', 'available', '2026-11-25 10:06:31.928447+00');


--
-- Name: properties_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.properties_id_seq', 20, true);


--
-- PostgreSQL database dump complete
--

\unrestrict QBeorOy4E4stz64aGoBSqeLx6NOJQyXad1kMFcsbRkgRXGH3vdtUyjVqiFZvLVz

