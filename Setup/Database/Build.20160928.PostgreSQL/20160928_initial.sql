--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.4
-- Dumped by pg_dump version 9.5.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: dbo; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA dbo;


ALTER SCHEMA dbo OWNER TO postgres;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA dbo;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = dbo, pg_catalog;

--
-- Name: GetObjectIdsForDashboard(integer, integer, timestamp without time zone); Type: FUNCTION; Schema: dbo; Owner: postgres
--

CREATE FUNCTION "GetObjectIdsForDashboard"("UserId" integer, "Amount" integer DEFAULT 10, "OlderThanDate" timestamp without time zone DEFAULT NULL::date) RETURNS TABLE(type text, id integer, date timestamp without time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
RETURN QUERY

SELECT
	"Type"
 ,	"Id"
 ,	"Date"
FROM
(
	SELECT
		objs."UserId"
	 ,	objs."Type"
	 ,	objs."Id"
	 ,	objs."Date"
	 ,	ROW_NUMBER() OVER (ORDER BY objs."Date" DESC) as "RowNumber"
	FROM
		dbo."UserConnection" conn
	JOIN
	(
		SELECT
			"CreatedBy" as "UserId"
		 ,	'Recipe' as "Type"
		 ,	"RecipeId" as "Id"
		 ,	"DateCreated" as "Date"
		FROM
			dbo."Recipe"
		WHERE
			"DateCreated" < coalesce("OlderThanDate", now())
			AND "IsActive" = true
			AND "IsPublic" = true
		UNION
	
		SELECT
			sess."UserId" as "UserId"
		 ,	'BrewSession' as "Type"
		 ,	"BrewSessionId" as "Id"
		 ,	"BrewDate" as "Date"
		FROM
			dbo."BrewSession" sess
		WHERE
			"BrewDate" < coalesce("OlderThanDate", now())
			AND "IsActive" = true
			AND "IsPublic" = true
		UNION

		SELECT
			note."UserId" as "UserId"
		 ,	'TastingNote' as "Type"
		 ,	"TastingNoteId" as "Id"
		 ,	"TasteDate" as "Date"
		FROM
			dbo."TastingNoteSummary" note
		WHERE
			"DateCreated" < coalesce("OlderThanDate", now()) 

	) objs
	 ON 
		conn."UserId" = objs."UserId"
	 WHERE
		conn."FollowedById" = $1
		AND
		conn."IsActive" = true
) T
WHERE
	"RowNumber" <= "Amount";

END;
$_$;


ALTER FUNCTION dbo."GetObjectIdsForDashboard"("UserId" integer, "Amount" integer, "OlderThanDate" timestamp without time zone) OWNER TO postgres;

--
-- Name: GetObjectIdsForDashboardNewest(integer, timestamp without time zone); Type: FUNCTION; Schema: dbo; Owner: postgres
--

CREATE FUNCTION "GetObjectIdsForDashboardNewest"("Amount" integer DEFAULT 10, "OlderThanDate" timestamp without time zone DEFAULT NULL::date) RETURNS TABLE(type text, id integer, date timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN QUERY

SELECT
	"Type"
 ,	"Id"
 ,	"Date"
FROM
(
	SELECT
		objs."UserId"
	 ,	objs."Type"
	 ,	objs."Id"
	 ,	objs."Date"
	 ,	ROW_NUMBER() OVER (ORDER BY objs."Date" DESC) as "RowNumber"
	 FROM
	(
		SELECT
			"CreatedBy" as "UserId"
		 ,	'Recipe' as "Type"
		 ,	"RecipeId" as "Id"
		 ,	"DateCreated" as "Date"
		FROM
			dbo."Recipe"
		WHERE
			"DateCreated" < coalesce("OlderThanDate", now())
			AND "IsActive" = true
			AND "IsPublic" = true
		UNION
	
		SELECT
			"UserId" as "UserId"
		 ,	'BrewSession' as "Type"
		 ,	"BrewSessionId" as "Id"
		 ,	"BrewDate"	as "Date"
		FROM
			dbo."BrewSession"
		WHERE
			"BrewDate" < coalesce("OlderThanDate", now())
			AND "IsActive" = true
			AND "IsPublic" = true

		UNION

		SELECT
			"UserId" as "UserId"
		 ,	'TastingNote' as "Type"
		 ,	"TastingNoteId" as "Id"
		 ,	"TasteDate" as "Date"
		FROM
			dbo."TastingNoteSummary"
		WHERE
			"DateCreated" < coalesce("OlderThanDate", now()) 
	) objs
) T
WHERE
	"RowNumber" <= "Amount";

END;
$$;


ALTER FUNCTION dbo."GetObjectIdsForDashboardNewest"("Amount" integer, "OlderThanDate" timestamp without time zone) OWNER TO postgres;

--
-- Name: User_CalculatedUserName_Trigger_Function(); Type: FUNCTION; Schema: dbo; Owner: postgres
--

CREATE FUNCTION "User_CalculatedUserName_Trigger_Function"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  NEW."CalculatedUsername"=case when NEW."HasCustomUsername"=(true) then NEW."Username" else 'Brewer '|| NEW."UserId" end;
  RETURN NEW;
end;
$$;


ALTER FUNCTION dbo."User_CalculatedUserName_Trigger_Function"() OWNER TO postgres;

SET search_path = pg_catalog;

--
-- Name: CAST (character varying AS uuid); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (character varying AS uuid) WITH INOUT AS IMPLICIT;


SET search_path = dbo, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: Adjunct; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "Adjunct" (
    "AdjunctId" integer NOT NULL,
    "CreatedByUserId" integer,
    "Name" character varying(150) NOT NULL,
    "Description" character varying(5000),
    "IsActive" boolean NOT NULL,
    "IsPublic" boolean NOT NULL,
    "DateCreated" timestamp without time zone NOT NULL,
    "DatePromoted" timestamp without time zone,
    "Category" character varying(50)
);


ALTER TABLE "Adjunct" OWNER TO postgres;

--
-- Name: AdjunctUsageType; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "AdjunctUsageType" (
    "AdjunctUsageTypeId" integer NOT NULL,
    "AdjunctUsageTypeName" character varying(25) NOT NULL
);


ALTER TABLE "AdjunctUsageType" OWNER TO postgres;

--
-- Name: BjcpStyle; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "BjcpStyle" (
    "Class" character varying(10),
    "CategoryId" integer,
    "CategoryName" character varying(50) NOT NULL,
    "SubCategoryId" character varying(5) NOT NULL,
    "SubCategoryName" character varying(50),
    "Aroma" character varying(5000),
    "Appearance" character varying(5000),
    "Flavor" character varying(5000),
    "Mouthfeel" character varying(5000),
    "Impression" character varying(5000),
    "Comments" character varying(5000),
    "Ingredients" character varying(5000),
    "Og_Low" double precision,
    "Og_High" double precision,
    "Fg_Low" double precision,
    "Fg_High" double precision,
    "Ibu_Low" integer,
    "Ibu_High" integer,
    "Srm_Low" double precision,
    "Srm_High" double precision,
    "Abv_Low" double precision,
    "Abv_High" double precision,
    "Examples" character varying(5000)
);


ALTER TABLE "BjcpStyle" OWNER TO postgres;

--
-- Name: BjcpStyleUrlFriendlyName; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "BjcpStyleUrlFriendlyName" (
    "SubCategoryId" character varying(5) NOT NULL,
    "UrlFriendlyName" character varying(50) NOT NULL
);


ALTER TABLE "BjcpStyleUrlFriendlyName" OWNER TO postgres;

--
-- Name: Recipe; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "Recipe" (
    "RecipeId" integer NOT NULL,
    "RecipeTypeId" integer,
    "OriginalRecipeId" integer,
    "CreatedBy" integer NOT NULL,
    "BjcpStyleSubCategoryId" character varying(5),
    "RecipeName" character varying(100) NOT NULL,
    "ImageUrlRoot" character varying(255),
    "Description" character varying(2000),
    "BatchSize" double precision NOT NULL,
    "BoilSize" double precision NOT NULL,
    "BoilTime" integer NOT NULL,
    "Efficiency" double precision NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsPublic" boolean DEFAULT true NOT NULL,
    "DateCreated" timestamp without time zone DEFAULT now() NOT NULL,
    "DateModified" timestamp without time zone,
    "Og" double precision NOT NULL,
    "Fg" double precision NOT NULL,
    "Srm" double precision NOT NULL,
    "Ibu" double precision NOT NULL,
    "BgGu" double precision NOT NULL,
    "Abv" double precision NOT NULL,
    "Calories" integer NOT NULL,
    "UnitTypeId" integer DEFAULT 10 NOT NULL,
    "IbuFormulaId" integer DEFAULT 10 NOT NULL
);


ALTER TABLE "Recipe" OWNER TO postgres;

--
-- Name: BjcpStyleSummary; Type: VIEW; Schema: dbo; Owner: postgres
--

CREATE VIEW "BjcpStyleSummary" AS
 SELECT sty."SubCategoryId",
    sty."SubCategoryName",
    sty."CategoryId",
    sty."CategoryName",
    frnm."UrlFriendlyName",
    count(rcp."RecipeId") AS "RecipeCount"
   FROM (("BjcpStyle" sty
     JOIN "BjcpStyleUrlFriendlyName" frnm ON (((sty."SubCategoryId")::text = (frnm."SubCategoryId")::text)))
     LEFT JOIN "Recipe" rcp ON ((((sty."SubCategoryId")::text = (rcp."BjcpStyleSubCategoryId")::text) AND (rcp."IsActive" = true) AND (rcp."IsPublic" = true))))
  GROUP BY sty."SubCategoryId", sty."SubCategoryName", sty."CategoryId", sty."CategoryName", frnm."UrlFriendlyName";


ALTER TABLE "BjcpStyleSummary" OWNER TO postgres;

--
-- Name: BrewSession; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "BrewSession" (
    "BrewSessionId" integer NOT NULL,
    "RecipeId" integer NOT NULL,
    "UserId" integer NOT NULL,
    "UnitTypeId" integer NOT NULL,
    "BrewDate" timestamp without time zone NOT NULL,
    "Notes" character varying(8000),
    "GrainWeight" double precision,
    "GrainTemp" double precision,
    "BoilTime" double precision,
    "BoilVolumeEst" double precision,
    "FermentVolumeEst" double precision,
    "TargetMashTemp" double precision,
    "MashThickness" double precision,
    "TotalWaterNeeded" double precision,
    "StrikeWaterTemp" double precision,
    "StrikeWaterVolume" double precision,
    "FirstRunningsVolume" double precision,
    "SpargeWaterVolume" double precision,
    "BrewKettleLoss" double precision,
    "WortShrinkage" double precision,
    "MashTunLoss" double precision,
    "BoilLoss" double precision,
    "MashGrainAbsorption" double precision,
    "SpargeGrainAbsorption" double precision,
    "MashPH" double precision,
    "MashStartTemp" double precision,
    "MashEndTemp" double precision,
    "MashTime" integer,
    "BoilVolumeActual" double precision,
    "PreBoilGravity" double precision,
    "BoilTimeActual" integer,
    "PostBoilVolume" double precision,
    "FermentVolumeActual" double precision,
    "OriginalGravity" double precision,
    "FinalGravity" double precision,
    "ConditionDate" timestamp without time zone,
    "ConditionTypeId" integer,
    "PrimingSugarType" character varying(150),
    "PrimingSugarAmount" double precision,
    "KegPSI" integer,
    "IsPublic" boolean NOT NULL,
    "IsActive" boolean NOT NULL,
    "DateCreated" timestamp without time zone NOT NULL,
    "DateModified" timestamp without time zone
);


ALTER TABLE "BrewSession" OWNER TO postgres;

--
-- Name: BrewSessionComment; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "BrewSessionComment" (
    "BrewSessionCommentId" integer NOT NULL,
    "UserId" integer NOT NULL,
    "BrewSessionId" integer NOT NULL,
    "CommentText" character varying(2000) NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "DateCreated" timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE "BrewSessionComment" OWNER TO postgres;

--
-- Name: TastingNote; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "TastingNote" (
    "TastingNoteId" integer NOT NULL,
    "BrewSessionId" integer,
    "RecipeId" integer,
    "UserId" integer NOT NULL,
    "TasteDate" timestamp without time zone NOT NULL,
    "Rating" double precision NOT NULL,
    "Notes" character varying(1000),
    "IsPublic" boolean NOT NULL,
    "IsActive" boolean NOT NULL,
    "DateCreated" timestamp without time zone NOT NULL,
    "DateModified" timestamp without time zone
);


ALTER TABLE "TastingNote" OWNER TO postgres;

--
-- Name: User; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "User" (
    "UserId" integer NOT NULL,
    "Username" character varying(50) DEFAULT uuid_generate_v1(),
    "EmailAddress" character varying(255) NOT NULL,
    "Password" bytea NOT NULL,
    "FirstName" character varying(25),
    "LastName" character varying(25),
    "HasCustomUsername" boolean NOT NULL,
    "IsActive" boolean NOT NULL,
    "CalculatedUsername" character varying,
    "DateCreated" timestamp without time zone NOT NULL,
    "DateModified" timestamp without time zone,
    "Bio" character varying(450)
);


ALTER TABLE "User" OWNER TO postgres;

--
-- Name: BrewSessionSummary; Type: VIEW; Schema: dbo; Owner: postgres
--

CREATE VIEW "BrewSessionSummary" AS
 SELECT brw."BrewSessionId",
    brw."RecipeId",
    rcp."RecipeTypeId",
    rcp."RecipeName",
    rcp."BjcpStyleSubCategoryId" AS "RecipeBjcpStyleSubCategoryId",
    COALESCE(sty."SubCategoryName", 'Unknown Style'::character varying) AS "RecipeBjcpStyleName",
    brw."UserId" AS "BrewedBy",
    usr."CalculatedUsername" AS "BrewedByUsername",
    usr."EmailAddress" AS "BrewedByUserEmail",
    brw."BrewDate",
    rcp."ImageUrlRoot" AS "RecipeImageUrlRoot",
    "left"(rtrim(ltrim((brw."Notes")::text)), 1000) AS "Summary",
    (
        CASE
            WHEN ((brw."GrainWeight" IS NOT NULL) OR (brw."GrainTemp" IS NOT NULL) OR (brw."BoilTime" IS NOT NULL) OR (brw."BoilVolumeEst" IS NOT NULL) OR (brw."FermentVolumeEst" IS NOT NULL) OR (brw."TargetMashTemp" IS NOT NULL) OR (brw."MashThickness" IS NOT NULL)) THEN 1
            ELSE 0
        END)::bit(1) AS "HasWaterInfusion",
    (
        CASE
            WHEN ((brw."MashPH" IS NOT NULL) OR (brw."MashStartTemp" IS NOT NULL) OR (brw."MashEndTemp" IS NOT NULL) OR (brw."MashTime" IS NOT NULL) OR (brw."BoilVolumeActual" IS NOT NULL) OR (brw."PreBoilGravity" IS NOT NULL) OR (brw."BoilTimeActual" IS NOT NULL) OR (brw."PostBoilVolume" IS NOT NULL)) THEN 1
            ELSE 0
        END)::bit(1) AS "HasMashBoil",
    (
        CASE
            WHEN ((brw."FermentVolumeActual" IS NOT NULL) OR (brw."OriginalGravity" IS NOT NULL) OR (brw."FinalGravity" IS NOT NULL)) THEN 1
            ELSE 0
        END)::bit(1) AS "HasFermentation",
    (
        CASE
            WHEN ((brw."ConditionDate" IS NOT NULL) OR (brw."ConditionTypeId" IS NOT NULL) OR (brw."PrimingSugarType" IS NOT NULL) OR (brw."PrimingSugarAmount" IS NOT NULL) OR (brw."KegPSI" IS NOT NULL)) THEN 1
            ELSE 0
        END)::bit(1) AS "HasConditioning",
    (
        CASE
            WHEN (tast."Count" IS NOT NULL) THEN 1
            ELSE 0
        END)::bit(1) AS "HasTastingNotes",
    rcp."Srm" AS "RecipeSrm",
    brw."IsActive",
    brw."IsPublic",
    brw."DateCreated",
    brw."DateModified"
   FROM (((("BrewSession" brw
     JOIN "User" usr ON ((usr."UserId" = brw."UserId")))
     JOIN "Recipe" rcp ON ((rcp."RecipeId" = brw."RecipeId")))
     LEFT JOIN "BjcpStyle" sty ON (((rcp."BjcpStyleSubCategoryId")::text = (sty."SubCategoryId")::text)))
     LEFT JOIN ( SELECT "TastingNote"."BrewSessionId",
            count(*) AS "Count"
           FROM "TastingNote"
          GROUP BY "TastingNote"."BrewSessionId") tast ON ((tast."BrewSessionId" = brw."BrewSessionId")))
  WHERE ((rcp."IsActive" = true) AND (rcp."IsPublic" = true));


ALTER TABLE "BrewSessionSummary" OWNER TO postgres;

--
-- Name: Content; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "Content" (
    "ContentId" integer NOT NULL,
    "ContentTypeId" integer NOT NULL,
    "Name" character varying(100) NOT NULL,
    "ShortName" character varying(25) NOT NULL,
    "Text" character varying NOT NULL,
    "IsActive" boolean NOT NULL,
    "IsPublic" boolean NOT NULL,
    "CreatedBy" integer NOT NULL,
    "ModifiedBy" integer,
    "DateCreated" timestamp without time zone NOT NULL,
    "DateModified" timestamp without time zone
);


ALTER TABLE "Content" OWNER TO postgres;

--
-- Name: ContentType; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "ContentType" (
    "ContentTypeId" integer NOT NULL,
    "ContentTypeName" character varying(50) NOT NULL
);


ALTER TABLE "ContentType" OWNER TO postgres;

--
-- Name: Exceptions; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "Exceptions" (
    "Id" bigint NOT NULL,
    "GUID" uuid NOT NULL,
    "ApplicationName" character varying(50) NOT NULL,
    "MachineName" character varying(50) NOT NULL,
    "CreationDate" timestamp without time zone NOT NULL,
    "Type" character varying(100) NOT NULL,
    "IsProtected" boolean DEFAULT false NOT NULL,
    "Host" character varying(100),
    "Url" character varying(500),
    "HTTPMethod" character varying(10),
    "IPAddress" character varying(40),
    "Source" character varying(100),
    "Message" character varying(1000),
    "Detail" character varying,
    "StatusCode" integer,
    "SQL" character varying,
    "DeletionDate" timestamp without time zone,
    "FullJson" character varying,
    "ErrorHash" integer,
    "DuplicateCount" integer DEFAULT 1 NOT NULL
);


ALTER TABLE "Exceptions" OWNER TO postgres;

--
-- Name: Fermentable; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "Fermentable" (
    "FermentableId" integer NOT NULL,
    "CreatedByUserId" integer,
    "Name" character varying(50) NOT NULL,
    "Description" character varying(5000),
    "Ppg" integer NOT NULL,
    "Lovibond" integer NOT NULL,
    "DefaultUsageTypeId" integer NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "IsPublic" boolean DEFAULT false NOT NULL,
    "DateCreated" timestamp without time zone DEFAULT now() NOT NULL,
    "DatePromoted" timestamp without time zone,
    "Category" character varying(50)
);


ALTER TABLE "Fermentable" OWNER TO postgres;

--
-- Name: FermentableUsageType; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "FermentableUsageType" (
    "FermentableUsageTypeId" integer NOT NULL,
    "FermentableUsageTypeName" character varying(50) NOT NULL
);


ALTER TABLE "FermentableUsageType" OWNER TO postgres;

--
-- Name: Hop; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "Hop" (
    "HopId" integer NOT NULL,
    "CreatedByUserId" integer,
    "Name" character varying(50) NOT NULL,
    "Description" character varying(5000),
    "AA" double precision NOT NULL,
    "IsActive" boolean NOT NULL,
    "IsPublic" boolean NOT NULL,
    "DateCreated" timestamp without time zone NOT NULL,
    "DatePromoted" timestamp without time zone,
    "Country" character varying(50),
    "Category" character varying(50)
);


ALTER TABLE "Hop" OWNER TO postgres;

--
-- Name: HopType; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "HopType" (
    "HopTypeId" integer NOT NULL,
    "HopTypeName" character varying(25) NOT NULL
);


ALTER TABLE "HopType" OWNER TO postgres;

--
-- Name: HopUsageType; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "HopUsageType" (
    "HopUsageTypeId" integer NOT NULL,
    "HopUsageTypeName" character varying(25) NOT NULL
);


ALTER TABLE "HopUsageType" OWNER TO postgres;

--
-- Name: IbuFormula; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "IbuFormula" (
    "IbuFormulaId" integer NOT NULL,
    "IbuFormulaName" character varying(50) NOT NULL
);


ALTER TABLE "IbuFormula" OWNER TO postgres;

--
-- Name: IngredientCategory; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "IngredientCategory" (
    "IngredientTypeId" integer NOT NULL,
    "Category" character varying(50) NOT NULL,
    "Rank" integer DEFAULT 9999
);


ALTER TABLE "IngredientCategory" OWNER TO postgres;

--
-- Name: IngredientType; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "IngredientType" (
    "IngredientTypeId" integer NOT NULL,
    "IngredientTypeName" character varying(50) NOT NULL
);


ALTER TABLE "IngredientType" OWNER TO postgres;

--
-- Name: MashStep; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "MashStep" (
    "MashStepId" integer NOT NULL,
    "CreatedByUserId" integer,
    "Name" character varying(150) NOT NULL,
    "Description" character varying(5000),
    "IsActive" boolean NOT NULL,
    "IsPublic" boolean NOT NULL,
    "DateCreated" timestamp without time zone DEFAULT now() NOT NULL,
    "DatePromoted" timestamp without time zone,
    "Category" character varying(50)
);


ALTER TABLE "MashStep" OWNER TO postgres;

--
-- Name: MiniUserSummary; Type: VIEW; Schema: dbo; Owner: postgres
--

CREATE VIEW "MiniUserSummary" AS
 SELECT "User"."UserId",
    "User"."CalculatedUsername" AS "Username",
    "User"."EmailAddress"
   FROM "User";


ALTER TABLE "MiniUserSummary" OWNER TO postgres;

--
-- Name: NewsletterSignup; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "NewsletterSignup" (
    "NewsletterSignupId" integer NOT NULL,
    "EmailAddress" character varying(250) NOT NULL,
    "IPAddress" character varying(25) NOT NULL,
    "Source" character varying(25) NOT NULL,
    "DateCreated" timestamp without time zone NOT NULL
);


ALTER TABLE "NewsletterSignup" OWNER TO postgres;

--
-- Name: NotificationType; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "NotificationType" (
    "NotificationTypeId" integer NOT NULL,
    "NotificationTypeName" character varying(50) NOT NULL
);


ALTER TABLE "NotificationType" OWNER TO postgres;

--
-- Name: OAuthProvider; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "OAuthProvider" (
    "OAuthProviderId" integer NOT NULL,
    "OAuthProviderName" character varying(50) NOT NULL,
    "IsActive" boolean NOT NULL
);


ALTER TABLE "OAuthProvider" OWNER TO postgres;

--
-- Name: Partner; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "Partner" (
    "PartnerId" integer NOT NULL,
    "Name" character varying(255) NOT NULL,
    "Token" character varying(10) NOT NULL,
    "ContactName" character varying(100),
    "ContactAddress1" character varying(50),
    "ContactAddress2" character varying(50),
    "ContactCity" character varying(50),
    "ContactStateProvince" character varying(50),
    "ContactPostalCode" character varying(50),
    "ContactCountry" character varying(2),
    "ContactPhone" character varying(15),
    "ContactFax" character varying(15),
    "ContactEmail" character varying(255),
    "IsActive" boolean NOT NULL,
    "IsPublic" boolean NOT NULL,
    "DateCreated" timestamp without time zone NOT NULL,
    "DateModified" timestamp without time zone
);


ALTER TABLE "Partner" OWNER TO postgres;

--
-- Name: PartnerSendToShopIngredient; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "PartnerSendToShopIngredient" (
    "PartnerId" integer NOT NULL,
    "IngredientTypeId" integer NOT NULL,
    "IngredientId" integer NOT NULL
);


ALTER TABLE "PartnerSendToShopIngredient" OWNER TO postgres;

--
-- Name: PartnerSendToShopSettings; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "PartnerSendToShopSettings" (
    "PartnerId" integer NOT NULL,
    "SendToShopMethodTypeId" integer NOT NULL,
    "SendToShopFormatTypeId" integer NOT NULL,
    "DayStart" integer NOT NULL,
    "DayEnd" integer NOT NULL,
    "HourStart" integer NOT NULL,
    "HourEnd" integer NOT NULL,
    "AllowOutOfRangeOrders" boolean NOT NULL,
    "DeliveryEmailAddress" character varying(255),
    "ConfirmationMessageText" character varying(2000) NOT NULL,
    "ContactPartnerMessageText" character varying(2000) NOT NULL,
    "ReadyForPickupMessageText" character varying(2000) NOT NULL,
    "CreatedBy" integer NOT NULL,
    "ModifiedBy" integer,
    "DateCreated" timestamp without time zone NOT NULL,
    "DateModified" timestamp without time zone
);


ALTER TABLE "PartnerSendToShopSettings" OWNER TO postgres;

--
-- Name: PartnerService; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "PartnerService" (
    "PartnerId" integer NOT NULL,
    "PartnerServiceTypeId" integer NOT NULL,
    "IsActive" boolean NOT NULL,
    "IsPublic" boolean DEFAULT true NOT NULL,
    "DateCreated" timestamp without time zone NOT NULL,
    "DateModified" timestamp without time zone
);


ALTER TABLE "PartnerService" OWNER TO postgres;

--
-- Name: PartnerServiceType; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "PartnerServiceType" (
    "PartnerServiceTypeId" integer NOT NULL,
    "PartnerServiceTypeName" character varying(50) NOT NULL
);


ALTER TABLE "PartnerServiceType" OWNER TO postgres;

--
-- Name: PartnerSummary; Type: VIEW; Schema: dbo; Owner: postgres
--

CREATE VIEW "PartnerSummary" AS
 SELECT "Partner"."PartnerId",
    "Partner"."Name"
   FROM "Partner"
  WHERE ("Partner"."IsActive" = true);


ALTER TABLE "PartnerSummary" OWNER TO postgres;

--
-- Name: RecipeAdjunct; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "RecipeAdjunct" (
    "RecipeAdjunctId" integer NOT NULL,
    "RecipeId" integer NOT NULL,
    "IngredientId" integer NOT NULL,
    "AdjunctUsageTypeId" integer NOT NULL,
    "Amount" double precision NOT NULL,
    "Unit" character varying(25) NOT NULL,
    "Rank" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "RecipeAdjunct" OWNER TO postgres;

--
-- Name: RecipeBrew; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "RecipeBrew" (
    "RecipeBrewId" integer NOT NULL,
    "RecipeId" integer NOT NULL,
    "BrewedBy" integer NOT NULL,
    "BrewDate" timestamp without time zone NOT NULL,
    "PostalCode" character varying(25) NOT NULL,
    "IsPublic" boolean NOT NULL,
    "IsActive" boolean NOT NULL,
    "DateCreated" timestamp without time zone NOT NULL,
    "DateModified" timestamp without time zone
);


ALTER TABLE "RecipeBrew" OWNER TO postgres;

--
-- Name: RecipeComment; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "RecipeComment" (
    "RecipeCommentId" integer NOT NULL,
    "UserId" integer NOT NULL,
    "RecipeId" integer NOT NULL,
    "CommentText" character varying(2000) NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "DateCreated" timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE "RecipeComment" OWNER TO postgres;

--
-- Name: RecipeCommentSummary; Type: VIEW; Schema: dbo; Owner: postgres
--

CREATE VIEW "RecipeCommentSummary" AS
 SELECT cmt."RecipeCommentId",
    cmt."UserId",
    cmt."RecipeId",
    usr."CalculatedUsername" AS "UserName",
    usr."EmailAddress",
    cmt."CommentText",
    cmt."DateCreated",
    cmt."IsActive"
   FROM ("RecipeComment" cmt
     JOIN "User" usr ON ((cmt."UserId" = usr."UserId")));


ALTER TABLE "RecipeCommentSummary" OWNER TO postgres;

--
-- Name: RecipeFermentable; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "RecipeFermentable" (
    "RecipeFermentableId" integer NOT NULL,
    "RecipeId" integer NOT NULL,
    "IngredientId" integer NOT NULL,
    "Ppg" integer NOT NULL,
    "Lovibond" integer NOT NULL,
    "Amount" double precision NOT NULL,
    "FermentableUsageTypeId" integer NOT NULL,
    "Rank" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "RecipeFermentable" OWNER TO postgres;

--
-- Name: RecipeHop; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "RecipeHop" (
    "RecipeHopId" integer NOT NULL,
    "RecipeId" integer NOT NULL,
    "IngredientId" integer NOT NULL,
    "HopUsageTypeId" integer NOT NULL,
    "HopTypeId" integer NOT NULL,
    "AlphaAcidAmount" double precision NOT NULL,
    "Amount" double precision NOT NULL,
    "TimeInMinutes" integer NOT NULL,
    "Rank" integer DEFAULT 0 NOT NULL,
    "Ibu" double precision DEFAULT 0 NOT NULL
);


ALTER TABLE "RecipeHop" OWNER TO postgres;

--
-- Name: RecipeMashStep; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "RecipeMashStep" (
    "RecipeMashStepId" integer NOT NULL,
    "RecipeId" integer NOT NULL,
    "IngredientId" integer NOT NULL,
    "Heat" character varying(50) NOT NULL,
    "Temp" double precision NOT NULL,
    "Time" integer NOT NULL,
    "Rank" integer NOT NULL
);


ALTER TABLE "RecipeMashStep" OWNER TO postgres;

--
-- Name: UserAdmin; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "UserAdmin" (
    "UserId" integer NOT NULL,
    "IsActive" boolean NOT NULL,
    "DateCreated" timestamp without time zone NOT NULL
);


ALTER TABLE "UserAdmin" OWNER TO postgres;

--
-- Name: RecipeSummary; Type: VIEW; Schema: dbo; Owner: postgres
--

CREATE VIEW "RecipeSummary" AS
 SELECT rcp."RecipeId",
    rcp."RecipeTypeId",
    rcp."OriginalRecipeId",
    orig."RecipeName" AS "OriginalRecipeName",
    rcp."CreatedBy",
    usr."CalculatedUsername" AS "CreatedByUserName",
    usr."EmailAddress" AS "CreatedByUserEmail",
    rcp."UnitTypeId",
    rcp."IbuFormulaId",
    rcp."BjcpStyleSubCategoryId",
    COALESCE(sty."SubCategoryName", 'Unknown Style'::character varying) AS "BJCPStyleName",
    rcp."RecipeName",
    rcp."ImageUrlRoot",
    rcp."Description",
    rcp."BatchSize",
    rcp."BoilSize",
    rcp."BoilTime",
    rcp."Efficiency",
    rcp."IsActive",
    rcp."IsPublic",
    rcp."DateCreated",
    rcp."DateModified",
    rcp."Og",
    rcp."Fg",
    rcp."Srm",
    rcp."Ibu",
    rcp."BgGu",
    rcp."Abv",
    rcp."Calories",
    (
        CASE
            WHEN (adm."UserId" IS NOT NULL) THEN 1
            ELSE 0
        END)::bit(1) AS "UserIsAdmin",
    COALESCE(brwcount."BrewSessionCount", (0)::bigint) AS "BrewSessionCount"
   FROM ((((("Recipe" rcp
     JOIN "User" usr ON ((rcp."CreatedBy" = usr."UserId")))
     LEFT JOIN "Recipe" orig ON ((rcp."OriginalRecipeId" = orig."RecipeId")))
     LEFT JOIN "BjcpStyle" sty ON (((rcp."BjcpStyleSubCategoryId")::text = (sty."SubCategoryId")::text)))
     LEFT JOIN "UserAdmin" adm ON ((rcp."CreatedBy" = adm."UserId")))
     LEFT JOIN ( SELECT brw."RecipeId",
            count(brw."BrewSessionId") AS "BrewSessionCount"
           FROM "BrewSession" brw
          WHERE ((brw."IsActive" = true) AND (brw."IsPublic" = true))
          GROUP BY brw."RecipeId") brwcount ON ((rcp."RecipeId" = brwcount."RecipeId")));


ALTER TABLE "RecipeSummary" OWNER TO postgres;

--
-- Name: TastingNoteSummary; Type: VIEW; Schema: dbo; Owner: postgres
--

CREATE VIEW "TastingNoteSummary" AS
 SELECT note."TastingNoteId",
    note."BrewSessionId",
    COALESCE(rec."RecipeId", recalt."RecipeId") AS "RecipeId",
    COALESCE(rec."RecipeName", recalt."RecipeName") AS "RecipeName",
    COALESCE(rec."BJCPStyleName", recalt."BJCPStyleName") AS "RecipeStyleName",
    COALESCE(rec."ImageUrlRoot", recalt."ImageUrlRoot") AS "RecipeImage",
    COALESCE(rec."Srm", recalt."Srm") AS "RecipeSrm",
    note."UserId",
    usr."CalculatedUsername" AS "TastingUsername",
    usr."EmailAddress" AS "TastingUserEmailAddress",
    note."TasteDate",
    note."Rating",
    note."Notes",
    note."DateCreated"
   FROM (((("TastingNote" note
     LEFT JOIN "BrewSession" brew ON ((brew."BrewSessionId" = note."BrewSessionId")))
     LEFT JOIN "RecipeSummary" rec ON ((note."RecipeId" = rec."RecipeId")))
     LEFT JOIN "RecipeSummary" recalt ON ((brew."RecipeId" = recalt."RecipeId")))
     JOIN "User" usr ON ((usr."UserId" = note."UserId")))
  WHERE ((note."IsActive" = true) AND (note."IsPublic" = true) AND ((rec."RecipeId" IS NULL) OR ((rec."IsActive" = true) AND (rec."IsPublic" = true))) AND ((note."BrewSessionId" IS NULL) OR ((brew."IsActive" = true) AND (brew."IsPublic" = true))));


ALTER TABLE "TastingNoteSummary" OWNER TO postgres;

--
-- Name: RecipeMetaData; Type: VIEW; Schema: dbo; Owner: postgres
--

CREATE VIEW "RecipeMetaData" AS
 SELECT rec."RecipeId",
    COALESCE(avg(nte."Rating"), (0)::double precision) AS "AverageRating",
    count(nte."TastingNoteId") AS "TastingNoteCount",
    count(brw."BrewSessionId") AS "BrewSessionCount",
    count(rcom."RecipeCommentId") AS "CommentCount",
    count(clon."RecipeId") AS "CloneCount"
   FROM (((("Recipe" rec
     LEFT JOIN "BrewSession" brw ON (((rec."RecipeId" = brw."RecipeId") AND (brw."IsPublic" = true) AND (brw."IsActive" = true))))
     LEFT JOIN "TastingNoteSummary" nte ON ((rec."RecipeId" = nte."RecipeId")))
     LEFT JOIN "RecipeComment" rcom ON (((rec."RecipeId" = rcom."RecipeId") AND (rcom."IsActive" = true))))
     LEFT JOIN "Recipe" clon ON ((clon."OriginalRecipeId" = rec."RecipeId")))
  WHERE (rec."IsActive" = true)
  GROUP BY rec."RecipeId";


ALTER TABLE "RecipeMetaData" OWNER TO postgres;

--
-- Name: RecipeStep; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "RecipeStep" (
    "RecipeStepId" integer NOT NULL,
    "RecipeId" integer NOT NULL,
    "Description" character varying(250) NOT NULL,
    "Rank" integer,
    "DateCreated" timestamp without time zone NOT NULL,
    "DateModified" timestamp without time zone
);


ALTER TABLE "RecipeStep" OWNER TO postgres;

--
-- Name: RecipeType; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "RecipeType" (
    "RecipeTypeId" integer NOT NULL,
    "RecipeTypeName" character varying(50) NOT NULL
);


ALTER TABLE "RecipeType" OWNER TO postgres;

--
-- Name: RecipeYeast; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "RecipeYeast" (
    "RecipeYeastId" integer NOT NULL,
    "RecipeId" integer NOT NULL,
    "IngredientId" integer NOT NULL,
    "Attenuation" double precision NOT NULL,
    "Rank" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "RecipeYeast" OWNER TO postgres;

--
-- Name: SendToShopFormat; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "SendToShopFormat" (
    "SendToShopFormatTypeId" integer NOT NULL,
    "SendToShopFormatName" character varying(25) NOT NULL
);


ALTER TABLE "SendToShopFormat" OWNER TO postgres;

--
-- Name: SendToShopMethod; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "SendToShopMethod" (
    "SendToShopMethodTypeId" integer NOT NULL,
    "SendToShopMethodName" character varying(50) NOT NULL
);


ALTER TABLE "SendToShopMethod" OWNER TO postgres;

--
-- Name: SendToShopOrder; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "SendToShopOrder" (
    "SendToShopOrderId" integer NOT NULL,
    "PartnerId" integer NOT NULL,
    "UserId" integer NOT NULL,
    "RecipeId" integer NOT NULL,
    "SendToShopOrderStatusId" integer NOT NULL,
    "Name" character varying(128) NOT NULL,
    "EmailAddress" character varying(255) NOT NULL,
    "PhoneNumber" character varying(25) NOT NULL,
    "AllowTextMessages" boolean NOT NULL,
    "Comments" character varying(5000),
    "DateCreated" timestamp without time zone NOT NULL,
    "DateModified" timestamp without time zone
);


ALTER TABLE "SendToShopOrder" OWNER TO postgres;

--
-- Name: SendToShopOrderItem; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "SendToShopOrderItem" (
    "SendToShopOrderItemId" integer NOT NULL,
    "SendToShopOrderId" integer NOT NULL,
    "IngredientTypeId" integer NOT NULL,
    "IngredientId" integer NOT NULL,
    "Quantity" double precision NOT NULL,
    "Unit" character varying(25) NOT NULL,
    "Instructions" character varying(1000)
);


ALTER TABLE "SendToShopOrderItem" OWNER TO postgres;

--
-- Name: SendToShopOrderStatus; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "SendToShopOrderStatus" (
    "SendToShopOrderStatusId" integer NOT NULL,
    "SendToShopOrderStatusName" character varying(25) NOT NULL
);


ALTER TABLE "SendToShopOrderStatus" OWNER TO postgres;

--
-- Name: UnitType; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "UnitType" (
    "UnitTypeId" integer NOT NULL,
    "UnitTypeName" character varying(50) NOT NULL
);


ALTER TABLE "UnitType" OWNER TO postgres;

--
-- Name: UserAuthToken; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "UserAuthToken" (
    "UserAuthTokenId" integer NOT NULL,
    "UserId" integer NOT NULL,
    "AuthToken" character varying(500) NOT NULL,
    "ExpiryDate" timestamp without time zone NOT NULL
);


ALTER TABLE "UserAuthToken" OWNER TO postgres;

--
-- Name: UserConnection; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "UserConnection" (
    "UserId" integer NOT NULL,
    "FollowedById" integer NOT NULL,
    "IsActive" boolean NOT NULL,
    "DateCreated" timestamp without time zone NOT NULL,
    "DateModified" timestamp without time zone
);


ALTER TABLE "UserConnection" OWNER TO postgres;

--
-- Name: UserFeedback; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "UserFeedback" (
    "UserFeedbackId" integer NOT NULL,
    "UserId" integer,
    "Feedback" character varying(1000) NOT NULL,
    "UserHostAddress" character varying(50) NOT NULL,
    "DateCreated" timestamp without time zone NOT NULL,
    "DateResponded" timestamp without time zone,
    "RespondedBy" integer
);


ALTER TABLE "UserFeedback" OWNER TO postgres;

--
-- Name: UserLogin; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "UserLogin" (
    "UserId" integer NOT NULL,
    "LoginDate" timestamp without time zone NOT NULL
);


ALTER TABLE "UserLogin" OWNER TO postgres;

--
-- Name: UserNotificationType; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "UserNotificationType" (
    "UserId" integer NOT NULL,
    "NotificationTypeId" integer NOT NULL,
    "DateCreated" timestamp without time zone NOT NULL
);


ALTER TABLE "UserNotificationType" OWNER TO postgres;

--
-- Name: UserOAuthUserId; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "UserOAuthUserId" (
    "UserId" integer NOT NULL,
    "OAuthProviderId" integer NOT NULL,
    "OAuthUserId" character varying(250) NOT NULL,
    "DateCreated" timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE "UserOAuthUserId" OWNER TO postgres;

--
-- Name: UserPartnerAdmin; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "UserPartnerAdmin" (
    "UserId" integer NOT NULL,
    "PartnerId" integer NOT NULL,
    "IsActive" boolean NOT NULL,
    "DateCreated" timestamp without time zone NOT NULL,
    "DateModified" timestamp without time zone
);


ALTER TABLE "UserPartnerAdmin" OWNER TO postgres;

--
-- Name: UserSuggestion; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "UserSuggestion" (
    "UserSuggestionId" integer NOT NULL,
    "UserId" integer,
    "SuggestionText" character varying(500) NOT NULL,
    "UserHostAddress" character varying(50) NOT NULL,
    "DateCreated" timestamp without time zone NOT NULL
);


ALTER TABLE "UserSuggestion" OWNER TO postgres;

--
-- Name: UserSummary; Type: VIEW; Schema: dbo; Owner: postgres
--

CREATE VIEW "UserSummary" AS
 SELECT usr."UserId",
    usr."CalculatedUsername" AS "Username",
    usr."EmailAddress",
    usr."FirstName",
    usr."LastName",
    usr."DateCreated",
    usr."Bio",
    usr."IsActive",
    COALESCE(rcpcount."RecipeCount", (0)::bigint) AS "RecipeCount",
    COALESCE(brewcount."BrewSessionCount", (0)::bigint) AS "BrewSessionCount",
    COALESCE(commcount."CommentCount", (0)::bigint) AS "CommentCount",
    (
        CASE
            WHEN (adm."UserId" IS NOT NULL) THEN 1
            ELSE 0
        END)::bit(1) AS "IsAdmin",
    padm."IsPartner",
    usr."HasCustomUsername"
   FROM ((((("User" usr
     LEFT JOIN "UserAdmin" adm ON (((usr."UserId" = adm."UserId") AND (adm."IsActive" = true))))
     LEFT JOIN ( SELECT usr_1."UserId",
            (
                CASE
                    WHEN (count(padm_1."UserId") > 0) THEN 1
                    ELSE 0
                END)::bit(1) AS "IsPartner"
           FROM ("User" usr_1
             LEFT JOIN "UserPartnerAdmin" padm_1 ON (((usr_1."UserId" = padm_1."UserId") AND (padm_1."IsActive" = true))))
          GROUP BY usr_1."UserId") padm ON ((usr."UserId" = padm."UserId")))
     LEFT JOIN ( SELECT "Recipe"."CreatedBy",
            count(*) AS "RecipeCount"
           FROM "Recipe"
          WHERE (("Recipe"."IsActive" = true) AND ("Recipe"."IsPublic" = true))
          GROUP BY "Recipe"."CreatedBy") rcpcount ON ((usr."UserId" = rcpcount."CreatedBy")))
     LEFT JOIN ( SELECT "BrewSession"."UserId" AS "BrewedBy",
            count(*) AS "BrewSessionCount"
           FROM "BrewSession"
          WHERE (("BrewSession"."IsActive" = true) AND ("BrewSession"."IsPublic" = true))
          GROUP BY "BrewSession"."UserId") brewcount ON ((usr."UserId" = brewcount."BrewedBy")))
     LEFT JOIN ( SELECT "RecipeComment"."UserId",
            count(*) AS "CommentCount"
           FROM "RecipeComment"
          WHERE ("RecipeComment"."IsActive" = true)
          GROUP BY "RecipeComment"."UserId") commcount ON ((usr."UserId" = commcount."UserId")));


ALTER TABLE "UserSummary" OWNER TO postgres;

--
-- Name: Yeast; Type: TABLE; Schema: dbo; Owner: postgres
--

CREATE TABLE "Yeast" (
    "YeastId" integer NOT NULL,
    "CreatedByUserId" integer,
    "Name" character varying(150) NOT NULL,
    "Description" character varying(5000),
    "Attenuation" double precision NOT NULL,
    "IsActive" boolean NOT NULL,
    "IsPublic" boolean NOT NULL,
    "DateCreated" timestamp without time zone NOT NULL,
    "DatePromoted" timestamp without time zone,
    "Category" character varying(50)
);


ALTER TABLE "Yeast" OWNER TO postgres;

--
-- Name: adjunct_adjunctid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE adjunct_adjunctid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE adjunct_adjunctid_seq OWNER TO postgres;

--
-- Name: adjunct_adjunctid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE adjunct_adjunctid_seq OWNED BY "Adjunct"."AdjunctId";


--
-- Name: brewsession_brewsessionid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE brewsession_brewsessionid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE brewsession_brewsessionid_seq OWNER TO postgres;

--
-- Name: brewsession_brewsessionid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE brewsession_brewsessionid_seq OWNED BY "BrewSession"."BrewSessionId";


--
-- Name: brewsessioncomment_brewsessioncommentid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE brewsessioncomment_brewsessioncommentid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE brewsessioncomment_brewsessioncommentid_seq OWNER TO postgres;

--
-- Name: brewsessioncomment_brewsessioncommentid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE brewsessioncomment_brewsessioncommentid_seq OWNED BY "BrewSessionComment"."BrewSessionCommentId";


--
-- Name: content_contentid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE content_contentid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE content_contentid_seq OWNER TO postgres;

--
-- Name: content_contentid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE content_contentid_seq OWNED BY "Content"."ContentId";


--
-- Name: exceptions_id_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE exceptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE exceptions_id_seq OWNER TO postgres;

--
-- Name: exceptions_id_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE exceptions_id_seq OWNED BY "Exceptions"."Id";


--
-- Name: fermentable_fermentableid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE fermentable_fermentableid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE fermentable_fermentableid_seq OWNER TO postgres;

--
-- Name: fermentable_fermentableid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE fermentable_fermentableid_seq OWNED BY "Fermentable"."FermentableId";


--
-- Name: hop_hopid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE hop_hopid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE hop_hopid_seq OWNER TO postgres;

--
-- Name: hop_hopid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE hop_hopid_seq OWNED BY "Hop"."HopId";


--
-- Name: mashstep_mashstepid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE mashstep_mashstepid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mashstep_mashstepid_seq OWNER TO postgres;

--
-- Name: mashstep_mashstepid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE mashstep_mashstepid_seq OWNED BY "MashStep"."MashStepId";


--
-- Name: newslettersignup_newslettersignupid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE newslettersignup_newslettersignupid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE newslettersignup_newslettersignupid_seq OWNER TO postgres;

--
-- Name: newslettersignup_newslettersignupid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE newslettersignup_newslettersignupid_seq OWNED BY "NewsletterSignup"."NewsletterSignupId";


--
-- Name: partner_partnerid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE partner_partnerid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE partner_partnerid_seq OWNER TO postgres;

--
-- Name: partner_partnerid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE partner_partnerid_seq OWNED BY "Partner"."PartnerId";


--
-- Name: recipe_recipeid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE recipe_recipeid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recipe_recipeid_seq OWNER TO postgres;

--
-- Name: recipe_recipeid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE recipe_recipeid_seq OWNED BY "Recipe"."RecipeId";


--
-- Name: recipeadjunct_recipeadjunctid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE recipeadjunct_recipeadjunctid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recipeadjunct_recipeadjunctid_seq OWNER TO postgres;

--
-- Name: recipeadjunct_recipeadjunctid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE recipeadjunct_recipeadjunctid_seq OWNED BY "RecipeAdjunct"."RecipeAdjunctId";


--
-- Name: recipebrew_recipebrewid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE recipebrew_recipebrewid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recipebrew_recipebrewid_seq OWNER TO postgres;

--
-- Name: recipebrew_recipebrewid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE recipebrew_recipebrewid_seq OWNED BY "RecipeBrew"."RecipeBrewId";


--
-- Name: recipecomment_recipecommentid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE recipecomment_recipecommentid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recipecomment_recipecommentid_seq OWNER TO postgres;

--
-- Name: recipecomment_recipecommentid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE recipecomment_recipecommentid_seq OWNED BY "RecipeComment"."RecipeCommentId";


--
-- Name: recipefermentable_recipefermentableid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE recipefermentable_recipefermentableid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recipefermentable_recipefermentableid_seq OWNER TO postgres;

--
-- Name: recipefermentable_recipefermentableid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE recipefermentable_recipefermentableid_seq OWNED BY "RecipeFermentable"."RecipeFermentableId";


--
-- Name: recipehop_recipehopid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE recipehop_recipehopid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recipehop_recipehopid_seq OWNER TO postgres;

--
-- Name: recipehop_recipehopid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE recipehop_recipehopid_seq OWNED BY "RecipeHop"."RecipeHopId";


--
-- Name: recipemashstep_recipemashstepid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE recipemashstep_recipemashstepid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recipemashstep_recipemashstepid_seq OWNER TO postgres;

--
-- Name: recipemashstep_recipemashstepid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE recipemashstep_recipemashstepid_seq OWNED BY "RecipeMashStep"."RecipeMashStepId";


--
-- Name: recipestep_recipestepid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE recipestep_recipestepid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recipestep_recipestepid_seq OWNER TO postgres;

--
-- Name: recipestep_recipestepid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE recipestep_recipestepid_seq OWNED BY "RecipeStep"."RecipeStepId";


--
-- Name: recipeyeast_recipeyeastid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE recipeyeast_recipeyeastid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recipeyeast_recipeyeastid_seq OWNER TO postgres;

--
-- Name: recipeyeast_recipeyeastid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE recipeyeast_recipeyeastid_seq OWNED BY "RecipeYeast"."RecipeYeastId";


--
-- Name: sendtoshoporder_sendtoshoporderid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE sendtoshoporder_sendtoshoporderid_seq
    START WITH 1001
    INCREMENT BY 1
    MINVALUE 1001
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sendtoshoporder_sendtoshoporderid_seq OWNER TO postgres;

--
-- Name: sendtoshoporder_sendtoshoporderid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE sendtoshoporder_sendtoshoporderid_seq OWNED BY "SendToShopOrder"."SendToShopOrderId";


--
-- Name: sendtoshoporderitem_sendtoshoporderitemid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE sendtoshoporderitem_sendtoshoporderitemid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sendtoshoporderitem_sendtoshoporderitemid_seq OWNER TO postgres;

--
-- Name: sendtoshoporderitem_sendtoshoporderitemid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE sendtoshoporderitem_sendtoshoporderitemid_seq OWNED BY "SendToShopOrderItem"."SendToShopOrderItemId";


--
-- Name: tastingnote_tastingnoteid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE tastingnote_tastingnoteid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tastingnote_tastingnoteid_seq OWNER TO postgres;

--
-- Name: tastingnote_tastingnoteid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE tastingnote_tastingnoteid_seq OWNED BY "TastingNote"."TastingNoteId";


--
-- Name: user_userid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE user_userid_seq
    START WITH 100000
    INCREMENT BY 1
    MINVALUE 100000
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_userid_seq OWNER TO postgres;

--
-- Name: user_userid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE user_userid_seq OWNED BY "User"."UserId";


--
-- Name: userauthtoken_userauthtokenid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE userauthtoken_userauthtokenid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE userauthtoken_userauthtokenid_seq OWNER TO postgres;

--
-- Name: userauthtoken_userauthtokenid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE userauthtoken_userauthtokenid_seq OWNED BY "UserAuthToken"."UserAuthTokenId";


--
-- Name: userfeedback_userfeedbackid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE userfeedback_userfeedbackid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE userfeedback_userfeedbackid_seq OWNER TO postgres;

--
-- Name: userfeedback_userfeedbackid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE userfeedback_userfeedbackid_seq OWNED BY "UserFeedback"."UserFeedbackId";


--
-- Name: usersuggestion_usersuggestionid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE usersuggestion_usersuggestionid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE usersuggestion_usersuggestionid_seq OWNER TO postgres;

--
-- Name: usersuggestion_usersuggestionid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE usersuggestion_usersuggestionid_seq OWNED BY "UserSuggestion"."UserSuggestionId";


--
-- Name: vw_UserActivityReport; Type: VIEW; Schema: dbo; Owner: postgres
--

CREATE VIEW "vw_UserActivityReport" AS
 SELECT usr."UserId",
    usr."FirstName",
    usr."LastName",
    usr."Username",
    lgn."LoginCount",
    COALESCE(rcp."RecipeCount", (0)::bigint) AS "RecipeCount",
    COALESCE(sess."BrewCount", (0)::bigint) AS "BrewCount",
    COALESCE(cmt."CommentCount", (0)::bigint) AS "CommentCount",
        CASE
            WHEN (oath."UserId" IS NOT NULL) THEN 1
            ELSE 0
        END AS "HasOAuth",
    COALESCE(ing."Total", (0)::numeric) AS "CustomIngredients",
        CASE
            WHEN (news."EmailAddress" IS NOT NULL) THEN 1
            ELSE 0
        END AS "EmailOptIn",
    COALESCE(sugg."SuggestionTotal", (0)::bigint) AS "Suggestions"
   FROM (((((((("User" usr
     JOIN ( SELECT "UserLogin"."UserId",
            count(*) AS "LoginCount"
           FROM "UserLogin"
          GROUP BY "UserLogin"."UserId") lgn ON ((usr."UserId" = lgn."UserId")))
     LEFT JOIN ( SELECT "Recipe"."CreatedBy",
            count(*) AS "RecipeCount"
           FROM "Recipe"
          GROUP BY "Recipe"."CreatedBy") rcp ON ((usr."UserId" = rcp."CreatedBy")))
     LEFT JOIN ( SELECT "BrewSession"."UserId" AS "BrewedBy",
            count("BrewSession"."BrewSessionId") AS "BrewCount"
           FROM "BrewSession"
          GROUP BY "BrewSession"."UserId") sess ON ((usr."UserId" = sess."BrewedBy")))
     LEFT JOIN ( SELECT "RecipeComment"."UserId",
            count(*) AS "CommentCount"
           FROM "RecipeComment"
          GROUP BY "RecipeComment"."UserId") cmt ON ((usr."UserId" = cmt."UserId")))
     LEFT JOIN "UserOAuthUserId" oath ON ((usr."UserId" = oath."UserId")))
     LEFT JOIN ( SELECT t."CreatedByUserId" AS "UserId",
            sum(t."Total") AS "Total"
           FROM ( SELECT "Fermentable"."CreatedByUserId",
                    count(*) AS "Total"
                   FROM "Fermentable"
                  WHERE ("Fermentable"."CreatedByUserId" IS NOT NULL)
                  GROUP BY "Fermentable"."CreatedByUserId"
                UNION
                 SELECT "Hop"."CreatedByUserId",
                    count(*) AS "Total"
                   FROM "Hop"
                  WHERE ("Hop"."CreatedByUserId" IS NOT NULL)
                  GROUP BY "Hop"."CreatedByUserId"
                UNION
                 SELECT "Yeast"."CreatedByUserId",
                    count(*) AS "Total"
                   FROM "Yeast"
                  WHERE ("Yeast"."CreatedByUserId" IS NOT NULL)
                  GROUP BY "Yeast"."CreatedByUserId"
                UNION
                 SELECT "Adjunct"."CreatedByUserId",
                    count(*) AS "Total"
                   FROM "Adjunct"
                  WHERE ("Adjunct"."CreatedByUserId" IS NOT NULL)
                  GROUP BY "Adjunct"."CreatedByUserId") t
          GROUP BY t."CreatedByUserId") ing ON ((usr."UserId" = ing."UserId")))
     LEFT JOIN "NewsletterSignup" news ON (((usr."EmailAddress")::text = (news."EmailAddress")::text)))
     LEFT JOIN ( SELECT sugg_1."UserId",
            count(*) AS "SuggestionTotal"
           FROM "UserSuggestion" sugg_1
          GROUP BY sugg_1."UserId") sugg ON ((usr."UserId" = sugg."UserId")))
  GROUP BY usr."UserId", usr."FirstName", usr."LastName", usr."Username", lgn."LoginCount", rcp."RecipeCount", sess."BrewCount", cmt."CommentCount", oath."UserId", ing."Total", news."EmailAddress", sugg."SuggestionTotal";


ALTER TABLE "vw_UserActivityReport" OWNER TO postgres;

--
-- Name: yeast_yeastid_seq; Type: SEQUENCE; Schema: dbo; Owner: postgres
--

CREATE SEQUENCE yeast_yeastid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE yeast_yeastid_seq OWNER TO postgres;

--
-- Name: yeast_yeastid_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: postgres
--

ALTER SEQUENCE yeast_yeastid_seq OWNED BY "Yeast"."YeastId";


--
-- Name: AdjunctId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Adjunct" ALTER COLUMN "AdjunctId" SET DEFAULT nextval('adjunct_adjunctid_seq'::regclass);


--
-- Name: BrewSessionId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "BrewSession" ALTER COLUMN "BrewSessionId" SET DEFAULT nextval('brewsession_brewsessionid_seq'::regclass);


--
-- Name: BrewSessionCommentId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "BrewSessionComment" ALTER COLUMN "BrewSessionCommentId" SET DEFAULT nextval('brewsessioncomment_brewsessioncommentid_seq'::regclass);


--
-- Name: ContentId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Content" ALTER COLUMN "ContentId" SET DEFAULT nextval('content_contentid_seq'::regclass);


--
-- Name: Id; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Exceptions" ALTER COLUMN "Id" SET DEFAULT nextval('exceptions_id_seq'::regclass);


--
-- Name: FermentableId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Fermentable" ALTER COLUMN "FermentableId" SET DEFAULT nextval('fermentable_fermentableid_seq'::regclass);


--
-- Name: HopId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Hop" ALTER COLUMN "HopId" SET DEFAULT nextval('hop_hopid_seq'::regclass);


--
-- Name: MashStepId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "MashStep" ALTER COLUMN "MashStepId" SET DEFAULT nextval('mashstep_mashstepid_seq'::regclass);


--
-- Name: NewsletterSignupId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "NewsletterSignup" ALTER COLUMN "NewsletterSignupId" SET DEFAULT nextval('newslettersignup_newslettersignupid_seq'::regclass);


--
-- Name: PartnerId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Partner" ALTER COLUMN "PartnerId" SET DEFAULT nextval('partner_partnerid_seq'::regclass);


--
-- Name: RecipeId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Recipe" ALTER COLUMN "RecipeId" SET DEFAULT nextval('recipe_recipeid_seq'::regclass);


--
-- Name: RecipeAdjunctId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeAdjunct" ALTER COLUMN "RecipeAdjunctId" SET DEFAULT nextval('recipeadjunct_recipeadjunctid_seq'::regclass);


--
-- Name: RecipeBrewId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeBrew" ALTER COLUMN "RecipeBrewId" SET DEFAULT nextval('recipebrew_recipebrewid_seq'::regclass);


--
-- Name: RecipeCommentId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeComment" ALTER COLUMN "RecipeCommentId" SET DEFAULT nextval('recipecomment_recipecommentid_seq'::regclass);


--
-- Name: RecipeFermentableId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeFermentable" ALTER COLUMN "RecipeFermentableId" SET DEFAULT nextval('recipefermentable_recipefermentableid_seq'::regclass);


--
-- Name: RecipeHopId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeHop" ALTER COLUMN "RecipeHopId" SET DEFAULT nextval('recipehop_recipehopid_seq'::regclass);


--
-- Name: RecipeMashStepId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeMashStep" ALTER COLUMN "RecipeMashStepId" SET DEFAULT nextval('recipemashstep_recipemashstepid_seq'::regclass);


--
-- Name: RecipeStepId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeStep" ALTER COLUMN "RecipeStepId" SET DEFAULT nextval('recipestep_recipestepid_seq'::regclass);


--
-- Name: RecipeYeastId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeYeast" ALTER COLUMN "RecipeYeastId" SET DEFAULT nextval('recipeyeast_recipeyeastid_seq'::regclass);


--
-- Name: SendToShopOrderId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "SendToShopOrder" ALTER COLUMN "SendToShopOrderId" SET DEFAULT nextval('sendtoshoporder_sendtoshoporderid_seq'::regclass);


--
-- Name: SendToShopOrderItemId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "SendToShopOrderItem" ALTER COLUMN "SendToShopOrderItemId" SET DEFAULT nextval('sendtoshoporderitem_sendtoshoporderitemid_seq'::regclass);


--
-- Name: TastingNoteId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "TastingNote" ALTER COLUMN "TastingNoteId" SET DEFAULT nextval('tastingnote_tastingnoteid_seq'::regclass);


--
-- Name: UserId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "User" ALTER COLUMN "UserId" SET DEFAULT nextval('user_userid_seq'::regclass);


--
-- Name: UserAuthTokenId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserAuthToken" ALTER COLUMN "UserAuthTokenId" SET DEFAULT nextval('userauthtoken_userauthtokenid_seq'::regclass);


--
-- Name: UserFeedbackId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserFeedback" ALTER COLUMN "UserFeedbackId" SET DEFAULT nextval('userfeedback_userfeedbackid_seq'::regclass);


--
-- Name: UserSuggestionId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserSuggestion" ALTER COLUMN "UserSuggestionId" SET DEFAULT nextval('usersuggestion_usersuggestionid_seq'::regclass);


--
-- Name: YeastId; Type: DEFAULT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Yeast" ALTER COLUMN "YeastId" SET DEFAULT nextval('yeast_yeastid_seq'::regclass);


--
-- Data for Name: Adjunct; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "Adjunct" VALUES (1, NULL, 'Allspice', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (2, NULL, 'Amylase Enzyme', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (3, NULL, 'Anise', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (4, NULL, 'Antifoam', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (5, NULL, 'Calcium Carbonate', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (6, NULL, 'Cinnamon', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (7, NULL, 'Clove', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (8, NULL, 'Coriander', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (9, NULL, 'Fermax Yeast Nutrient', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (10, NULL, 'Gelatin', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (11, NULL, 'Ginger', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (12, NULL, 'Gypsum', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (13, NULL, 'Hot pepper', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (14, NULL, 'Irish Moss', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (15, NULL, 'Juniper berries or boughs', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (16, NULL, 'Lactic Acid', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (17, NULL, 'Licorice', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (18, NULL, 'Liquid Isinglass', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (19, NULL, 'Nutmeg', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (20, NULL, 'Orange or Lemon peel', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (21, NULL, 'Polyclar', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (22, NULL, 'Potassium Metabisulfite', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (23, NULL, 'Sodium Metabisulfite', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (24, NULL, 'Sparkolloid', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (25, NULL, 'Spruce needles or twigs', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (26, NULL, 'Wormwood', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);
INSERT INTO "Adjunct" VALUES (27, NULL, 'Yarrow', NULL, true, true, '2012-05-01 21:31:22.633', NULL, NULL);


--
-- Data for Name: AdjunctUsageType; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "AdjunctUsageType" VALUES (10, 'Mash');
INSERT INTO "AdjunctUsageType" VALUES (20, 'Boil');
INSERT INTO "AdjunctUsageType" VALUES (25, 'FlameOut');
INSERT INTO "AdjunctUsageType" VALUES (30, 'Primary');
INSERT INTO "AdjunctUsageType" VALUES (40, 'Secondary');
INSERT INTO "AdjunctUsageType" VALUES (50, 'Bottle');


--
-- Data for Name: BjcpStyle; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "BjcpStyle" VALUES ('beer', 10, 'American Ale', '10A', 'American Pale Ale', 'Usually moderate to strong hop aroma from dry hopping or late kettle additions of American hop varieties.  A citrusy hop character is very common, but not required. Low to moderate maltiness supports the hop presentation, and may optionally show small amounts of specialty malt character (bready, toasty, biscuity).  Fruity esters vary from moderate to none.  No diacetyl.  Dry hopping (if used) may add grassy notes, although this character should not be excessive.', 'Pale golden to deep amber.  Moderately large white to off-white head with good retention.  Generally quite clear, although dry-hopped versions may be slightly hazy.', 'Usually a moderate to high hop flavor, often showing a citrusy American hop character (although other hop varieties may be used).  Low to moderately high clean malt character supports the hop presentation, and may optionally show small amounts of specialty malt character (bready, toasty, biscuity).  The balance is typically towards the late hops and bitterness, but the malt presence can be substantial.  Caramel flavors are usually restrained or absent.  Fruity esters can be moderate to none.  Moderate to high hop bitterness with a medium to dry finish.  Hop flavor and bitterness often lingers into the finish.  No diacetyl. Dry hopping (if used) may add grassy notes, although this character should not be excessive.', 'Medium-light to medium body.  Carbonation moderate to high.  Overall smooth finish without astringency often associated with high hopping rates.', 'Refreshing and hoppy, yet with sufficient supporting malt.', 'There is some overlap in color between American pale ale and American amber ale.  The American pale ale will generally be cleaner, have a less caramelly malt profile, less body, and often more finishing hops.', 'Pale ale malt, typically American two-row.  American hops, often but not always ones with a citrusy character.  American ale yeast.  Water can vary in sulfate content, but carbonate content should be relatively low.  Specialty grains may add character and complexity, but generally make up a relatively small portion of the grist.  Grains that add malt flavor and richness, light sweetness, and toasty or bready notes are often used (along with late hops) to differentiate brands.', 1.04499999999999993, 1.06000000000000005, 1.01000000000000001, 1.0149999999999999, 30, 45, 5, 14, 4.5, 6.20000000000000018, 'Sierra Nevada Pale Ale, Stone Pale Ale, Great Lakes Burning River Pale Ale, Bear Republic XP Pale Ale, Anderson Valley Poleeko Gold Pale Ale, Deschutes Mirror Pond, Full Sail Pale Ale, Three Floyds X-Tra Pale Ale, Firestone Pale Ale, Left Hand Brewing Jackman''s Pale Ale');
INSERT INTO "BjcpStyle" VALUES ('beer', 10, 'American Ale', '10B', 'American Amber Ale', 'Low to moderate hop aroma from dry hopping or late kettle additions of American hop varieties.  A citrusy hop character is common, but not required.  Moderately low to moderately high maltiness balances and sometimes masks the hop presentation, and usually shows a moderate caramel character. Esters vary from moderate to none.  No diacetyl.', 'Amber to coppery brown in color.  Moderately large off-white head with good retention.  Generally quite clear, although dry-hopped versions may be slightly hazy.', 'Moderate to high hop flavor from American hop varieties, which often but not always has a citrusy quality.  Malt flavors are moderate to strong, and usually show an initial malty sweetness followed by a moderate caramel flavor (and sometimes other character malts in lesser amounts).  Malt and hop bitterness are usually balanced and mutually supportive.  Fruity esters can be moderate to none.  Caramel sweetness and hop flavor/bitterness can linger somewhat into the medium to full finish.  No diacetyl.', 'Medium to medium-full body.  Carbonation moderate to high.  Overall smooth finish without astringency often associated with high hopping rates.  Stronger versions may have a slight alcohol warmth.', 'Like an American pale ale with more body, more caramel richness, and a balance more towards malt than hops (although hop rates can be significant).', 'Can overlap in color with American pale ales.  However, American amber ales differ from American pale ales not only by being usually darker in color, but also by having more caramel flavor, more body, and usually being balanced more evenly between malt and bitterness.  Should not have a strong chocolate or roast character that might suggest an American brown ale (although small amounts are OK).', 'Pale ale malt, typically American two-row.  Medium to dark crystal malts.  May also contain specialty grains which add additional character and uniqueness.  American hops, often with citrusy flavors, are common but others may also be used. Water can vary in sulfate and carbonate content.', 1.04499999999999993, 1.06000000000000005, 1.01000000000000001, 1.0149999999999999, 25, 40, 10, 17, 4.5, 6.20000000000000018, 'North Coast Red Seal Ale, TrÃ¶egs HopBack Amber Ale, Deschutes Cinder Cone Red, Pyramid Broken Rake, St. Rogue Red Ale, Anderson Valley Boont Amber Ale, Lagunitas Censored Ale, Avery Redpoint Ale, McNeill''s Firehouse Amber Ale, Mendocino Red Tail Ale, Bell''s Amber');
INSERT INTO "BjcpStyle" VALUES ('beer', 10, 'American Ale', '10C', 'American Brown Ale', 'Malty, sweet and rich, which often has a chocolate, caramel, nutty and/or toasty quality.  Hop aroma is typically low to moderate.  Some interpretations of the style may feature a stronger hop aroma, a citrusy American hop character, and/or a fresh dry-hopped aroma (all are optional).  Fruity esters are moderate to very low.  The dark malt character is more robust than other brown ales, yet stops short of being overly porter-like.  The malt and hops are generally balanced.  Moderately low to no diacetyl.', 'Light to very dark brown color.  Clear.  Low to moderate off-white to light tan head.', 'Medium to high malty flavor (often with caramel, toasty and/or chocolate flavors), with medium to medium-high bitterness.  The medium to medium-dry finish provides an aftertaste having both malt and hops.  Hop flavor can be light to moderate, and may optionally have a citrusy character.  Very low to moderate fruity esters.  Moderately low to no diacetyl.', 'Medium to medium-full body.  More bitter versions may have a dry, resiny impression.  Moderate to moderately high carbonation.  Stronger versions may have some alcohol warmth in the finish.', 'Can be considered a bigger, maltier, hoppier interpretation of Northern English brown ale or a hoppier, less malty Brown Porter, often including the citrus-accented hop presence that is characteristic of American hop varieties.', 'A strongly flavored, hoppy brown beer, originated by American home brewers.  Related to American Pale and American Amber Ales, although with more of a caramel and chocolate character, which tends to balance the hop bitterness and finish.  Most commercial American Browns are not as aggressive as the original homebrewed versions, and some modern craft brewed examples.  IPA-strength brown ales should be entered in the Specialty Beer category (23).', 'Well-modified pale malt, either American or Continental, plus crystal and darker malts should complete the malt bill.  American hops are typical, but UK or noble hops can also be used. Moderate carbonate water would appropriately balance the dark malt acidity.', 1.04499999999999993, 1.06000000000000005, 1.01000000000000001, 1.01600000000000001, 20, 40, 18, 35, 4.29999999999999982, 6.20000000000000018, 'Bell''s Best Brown, Smuttynose Old Brown Dog Ale, Big Sky Moose Drool Brown Ale, North Coast Acme Brown, Brooklyn Brown Ale, Lost Coast Downtown Brown, Left Hand Deep Cover Brown Ale');
INSERT INTO "BjcpStyle" VALUES ('beer', 11, 'English Brown Ale', '11A', 'Mild', 'Low to moderate malt aroma, and may have some fruitiness.  The malt expression can take on a wide range of character, which can include caramelly, grainy, toasted, nutty, chocolate, or lightly roasted.  Little to no hop aroma.  Very low to no diacetyl.', 'Copper to dark brown or mahogany color.  A few paler examples (medium amber to light brown) exist. Generally clear, although is traditionally unfiltered.  Low to moderate off-white to tan head.  Retention may be poor due to low carbonation, adjunct use and low gravity.', 'Generally a malty beer, although may have a very wide range of malt- and yeast-based flavors (e.g., malty, sweet, caramel, toffee, toast, nutty, chocolate, coffee, roast, vinous, fruit, licorice, molasses, plum, raisin).  Can finish sweet or dry.  Versions with darker malts may have a dry, roasted finish.  Low to moderate bitterness, enough to provide some balance but not enough to overpower the malt.  Fruity esters moderate to none.  Diacetyl and hop flavor low to none.', 'Light to medium body.  Generally low to medium-low carbonation.  Roast-based versions may have a light astringency.  Sweeter versions may seem to have a rather full mouthfeel for the gravity.', 'A light-flavored, malt-accented beer that is readily suited to drinking in quantity.  Refreshing, yet flavorful.  Some versions may seem like lower gravity brown porters.', 'Most are low-gravity session beers in the range 3.1-3.8%, although some versions may be made in the stronger (4%+) range for export, festivals, seasonal and/or special occasions.  Generally served on cask; session-strength bottled versions don''t often travel well.  A wide range of interpretations are possible.', 'Pale English base malts (often fairly dextrinous), crystal and darker malts should comprise the grist.  May use sugar adjuncts.  English hop varieties would be most suitable, though their character is muted.  Characterful English ale yeast.', 1.03000000000000003, 1.03800000000000003, 1.00800000000000001, 1.0129999999999999, 10, 25, 12, 25, 2.79999999999999982, 4.5, 'Moorhouse Black Cat, Gale''s Festival Mild, Theakston Traditional Mild, Highgate Mild, Sainsbury Mild, Brain''s Dark, Banks''s Mild, Coach House Gunpowder Strong Mild, Woodforde''s Mardler''s Mild, Greene King XX Mild, Motor City Brewing Ghettoblaster');
INSERT INTO "BjcpStyle" VALUES ('beer', 11, 'English Brown Ale', '11B', 'Southern English Brown', 'Malty-sweet, often with a rich, caramel or toffee-like character. Moderately fruity, often with notes of dark fruits such as plums and/or raisins.  Very low to no hop aroma.  No diacetyl.', 'Light to dark brown, and can be almost black.  Nearly opaque, although should be relatively clear if visible.  Low to moderate off-white to tan head.', 'Deep, caramel- or toffee-like malty sweetness on the palate and lasting into the finish.  Hints of biscuit and coffee are common.  May have a moderate dark fruit complexity.  Low hop bitterness.  Hop flavor is low to non-existent.  Little or no perceivable roasty or bitter black malt flavor.  Moderately sweet finish with a smooth, malty aftertaste.  Low to no diacetyl.', 'Medium body, but the residual sweetness may give a heavier impression.  Low to moderately low carbonation.  Quite creamy and smooth in texture, particularly for its gravity.', 'A luscious, malt-oriented brown ale, with a caramel, dark fruit complexity of malt flavor.  May seem somewhat like a smaller version of a sweet stout or a sweet version of a dark mild.', 'Increasingly rare; Mann''s has over 90% market share in Britain.  Some consider it a bottled version of dark mild, but this style is sweeter than virtually all modern examples of mild.', 'English pale ale malt as a base with a healthy proportion of darker caramel malts and often some roasted (black) malt and wheat malt.  Moderate to high carbonate water would appropriately balance the dark malt acidity.  English hop varieties are most authentic, though with low flavor and bitterness almost any type could be used.', 1.03299999999999992, 1.04200000000000004, 1.0109999999999999, 1.01400000000000001, 12, 20, 19, 35, 2.79999999999999982, 4.09999999999999964, 'Mann''s Brown Ale (bottled, but not available in the US), Harvey''s Nut Brown Ale, Woodeforde''s Norfolk Nog');
INSERT INTO "BjcpStyle" VALUES ('beer', 11, 'English Brown Ale', '11C', 'Northern English Brown Ale', 'Light, sweet malt aroma with toffee, nutty and/or caramel notes.  A light but appealing fresh hop aroma (UK varieties) may also be noticed.  A light fruity ester aroma may be evident in these beers, but should not dominate.  Very low to no diacetyl.', 'Dark amber to reddish-brown color.  Clear.  Low to moderate off-white to light tan head.', 'Gentle to moderate malt sweetness, with a nutty, lightly caramelly character and a medium-dry to dry finish.  Malt may also have a toasted, biscuity, or toffee-like character.  Medium to medium-low bitterness.  Malt-hop balance is nearly even, with hop flavor low to none (UK varieties).  Some fruity esters can be present; low diacetyl (especially butterscotch) is optional but acceptable.', 'Medium-light to medium body.  Medium to medium-high carbonation.', 'Drier and more hop-oriented that southern English brown ale, with a nutty character rather than caramel.', 'English brown ales are generally split into sub-styles along geographic lines.', 'English mild ale or pale ale malt base with caramel malts. May also have small amounts darker malts (e.g., chocolate) to provide color and the nutty character.  English hop varieties are most authentic. Moderate carbonate water.', 1.04000000000000004, 1.05200000000000005, 1.00800000000000001, 1.01400000000000001, 20, 30, 12, 22, 4.20000000000000018, 5.40000000000000036, 'Newcastle Brown Ale, Samuel Smith''s Nut Brown Ale, Riggwelter Yorkshire Ale, Wychwood Hobgoblin, TrÃ¶egs Rugged Trail Ale, Alesmith Nautical Nut Brown Ale, Avery Ellie''s Brown Ale, Goose Island Nut Brown Ale, Samuel Adams Brown Ale');
INSERT INTO "BjcpStyle" VALUES ('beer', 12, 'Porter', '12A', 'Brown Porter', 'Malt aroma with mild roastiness should be evident, and may have a chocolaty quality.  May also show some non-roasted malt character in support (caramelly, grainy, bready, nutty, toffee-like and/or sweet).  English hop aroma moderate to none.  Fruity esters moderate to none.  Diacetyl low to none.', 'Light brown to dark brown in color, often with ruby highlights when held up to light.  Good clarity, although may approach being opaque.  Moderate off-white to light tan head with good to fair retention.', 'Malt flavor includes a mild to moderate roastiness (frequently with a chocolate character) and often a significant caramel, nutty, and/or toffee character.  May have other secondary flavors such as coffee, licorice, biscuits or toast in support.  Should not have a significant black malt character (acrid, burnt, or harsh roasted flavors), although small amounts may contribute a bitter chocolate complexity.  English hop flavor moderate to none.  Medium-low to medium hop bitterness will vary the balance from slightly malty to slightly bitter.  Usually fairly well attenuated, although somewhat sweet versions exist.  Diacetyl should be moderately low to none.  Moderate to low fruity esters.', 'Medium-light to medium body.  Moderately low to moderately high carbonation.', 'A fairly substantial English dark ale with restrained roasty characteristics.', 'Differs from a robust porter in that it usually has softer, sweeter and more caramelly flavors, lower gravities, and usually less alcohol.  More substance and roast than a brown ale.  Higher in gravity than a dark mild.  Some versions are fermented with lager yeast.  Balance tends toward malt more than hops.  Usually has an "English" character.  Historical versions with Brettanomyces, sourness, or smokiness should be entered in the Specialty Beer category (23).', 'English ingredients are most common.  May contain several malts, including chocolate and/or other dark roasted malts and caramel-type malts. Historical versions would use a significant amount of brown malt.  Usually does not contain large amounts of black patent malt or roasted barley.  English hops are most common, but are usually subdued.  London or Dublin-type water (moderate carbonate hardness) is traditional.  English or Irish ale yeast, or occasionally lager yeast, is used.  May contain a moderate amount of adjuncts (sugars, maize, molasses, treacle, etc.).', 1.04000000000000004, 1.05200000000000005, 1.00800000000000001, 1.01400000000000001, 18, 35, 20, 30, 4, 5.40000000000000036, 'Fuller''s London Porter, Samuel Smith Taddy Porter, Burton Bridge Burton Porter, RCH Old Slug Porter, Nethergate Old Growler Porter, Hambleton Nightmare Porter, Harvey''s Tom Paine Original Old Porter, Salopian Entire Butt English Porter, St. Peters Old-Style Porter, Shepherd Neame Original Porter, Flag Porter, Wasatch Polygamy Porter');
INSERT INTO "BjcpStyle" VALUES ('beer', 12, 'Porter', '12B', 'Robust Porter', 'Roasty aroma (often with a lightly burnt, black malt character) should be noticeable and may be moderately strong. Optionally may also show some additional malt character in support (grainy, bready, toffee-like, caramelly, chocolate, coffee, rich, and/or sweet).  Hop aroma low to high (US or UK varieties).  Some American versions may be dry-hopped.  Fruity esters are moderate to none.  Diacetyl low to none.', 'Medium brown to very dark brown, often with ruby- or garnet-like highlights.  Can approach black in color.  Clarity may be difficult to discern in such a dark beer, but when not opaque will be clear (particularly when held up to the light).  Full, tan-colored head with moderately good head retention.', 'Moderately strong malt flavor usually features a lightly burnt, black malt character (and sometimes chocolate and/or coffee flavors) with a bit of roasty dryness in the finish.  Overall flavor may finish from dry to medium-sweet, depending on grist composition, hop bittering level, and attenuation. May have a sharp character from dark roasted grains, although should not be overly acrid, burnt or harsh.  Medium to high bitterness, which can be accentuated by the roasted malt.  Hop flavor can vary from low to moderately high (US or UK varieties, typically), and balances the roasted malt flavors.  Diacetyl low to none.  Fruity esters moderate to none.', 'Medium to medium-full body.  Moderately low to moderately high carbonation.  Stronger versions may have a slight alcohol warmth.  May have a slight astringency from roasted grains, although this character should not be strong.', 'A substantial, malty dark ale with a complex and flavorful roasty character.', 'Although a rather broad style open to brewer interpretation, it may be distinguished from Stout as lacking a strong roasted barley character.  It differs from a brown porter in that a black patent or roasted grain character is usually present, and it can be stronger in alcohol.  Roast intensity and malt flavors can also vary significantly.  May or may not have a strong hop character, and may or may not have significant fermentation by-products; thus may seem to have an "American" or "English" character.', 'May contain several malts, prominently dark roasted malts and grains, which often include black patent malt (chocolate malt and/or roasted barley may also be used in some versions).  Hops are used for bittering, flavor and/or aroma, and are frequently UK or US varieties.  Water with moderate to high carbonate hardness is typical.  Ale yeast can either be clean US versions or characterful English varieties.', 1.04800000000000004, 1.06499999999999995, 1.01200000000000001, 1.01600000000000001, 25, 50, 22, 35, 4.79999999999999982, 6.5, 'Great Lakes Edmund Fitzgerald Porter, Meantime London Porter, Anchor Porter, Smuttynose Robust Porter, Sierra Nevada Porter, Deschutes Black Butte Porter,  Boulevard Bully! Porter, Rogue Mocha Porter, Avery New World Porter, Bell''s Porter, Great Divide Saint Bridget''s Porter');
INSERT INTO "BjcpStyle" VALUES ('cider', 28, 'Specialty Cider and Perry', '28D', 'Other Specialty Cider/Perry', 'The cider character must always be present, and must fit with adjuncts.', 'Clear to brilliant. Color should be that of a common cider unless adjuncts are expected to contribute color.', 'The cider character must always be present, and must fit with adjuncts.', 'Average body, may show tannic (astringent) or heavy body as determined by adjuncts.', '', 'Entrants MUST specify all major ingredients and adjuncts. Entrants MUST specify carbonation level (still, petillant, or sparkling). Entrants MUST specify sweetness (dry or medium).', '', 1.04499999999999993, 1.10000000000000009, NULL, NULL, NULL, NULL, NULL, NULL, 5, 12, '[US] Red Barn Cider Fire Barrel (WA), AEppelTreow Pear Wine and Sparrow Spiced Cider (WI)');
INSERT INTO "BjcpStyle" VALUES ('beer', 12, 'Porter', '12C', 'Baltic Porter', 'Rich malty sweetness often containing caramel, toffee, nutty to deep toast, and/or licorice notes.  Complex alcohol and ester profile of moderate strength, and reminiscent of plums, prunes, raisins, cherries or currants, occasionally with a vinous Port-like quality.  Some darker malt character that is deep chocolate, coffee or molasses but never burnt.  No hops.  No sourness.  Very smooth.', 'Dark reddish copper to opaque dark brown (not black).  Thick, persistent tan-colored head.  Clear, although darker versions can be opaque.', 'As with aroma, has a rich malty sweetness with a complex blend of deep malt, dried fruit esters, and alcohol.  Has a prominent yet smooth schwarzbier-like roasted flavor that stops short of burnt.  Mouth-filling and very smooth.  Clean lager character; no diacetyl.  Starts sweet but darker malt flavors quickly dominates and persists through finish.  Just a touch dry with a hint of roast coffee or licorice in the finish.  Malt can have a caramel, toffee, nutty, molasses and/or licorice complexity.  Light hints of black currant and dark fruits.  Medium-low to medium bitterness from malt and hops, just to provide balance.  Hop flavor from slightly spicy hops (Lublin or Saaz types) ranges from none to medium-low.', 'Generally quite full-bodied and smooth, with a well-aged alcohol warmth (although the rarer lower gravity Carnegie-style versions will have a medium body and less warmth).  Medium to medium-high carbonation, making it seem even more mouth-filling.  Not heavy on the tongue due to carbonation level.  Most versions are in the 7-8.5% ABV range.', 'A Baltic Porter often has the malt flavors reminiscent of an English brown porter and the restrained roast of a schwarzbier, but with a higher OG and alcohol content than either.  Very complex, with multi-layered flavors.', 'May also be described as an Imperial Porter, although heavily roasted or hopped versions should be entered as either Imperial Stouts (13F) or Specialty Beers (23).', 'Generally lager yeast (cold fermented if using ale yeast).  Debittered chocolate or black malt.  Munich or Vienna base malt.  Continental hops.  May contain crystal malts and/or adjuncts.  Brown or amber malt common in historical recipes.', 1.06000000000000005, 1.09000000000000008, 1.01600000000000001, 1.02400000000000002, 20, 40, 17, 30, 5.5, 9.5, 'Sinebrychoff Porter (Finland), Okocim Porter (Poland), Zywiec Porter (Poland), Baltika #6 Porter (Russia), Carnegie Stark Porter (Sweden), Aldaris Porteris (Latvia), Utenos Porter (Lithuania), Stepan Razin Porter (Russia), NÃ¸gne Ã¸ porter (Norway), Neuzeller Kloster-BrÃ¤u Neuzeller Porter (Germany), Southampton Imperial Baltic Porter');
INSERT INTO "BjcpStyle" VALUES ('beer', 13, 'Stout', '13A', 'Dry Stout', 'Coffee-like roasted barley and roasted malt aromas are prominent; may have slight chocolate, cocoa and/or grainy secondary notes.  Esters medium-low to none.  No diacetyl.  Hop aroma low to none.', 'Jet black to deep brown with garnet highlights in color.  Can be opaque (if not, it should be clear).  A thick, creamy, long-lasting, tan- to brown-colored head is characteristic.', 'Moderate roasted, grainy sharpness, optionally with light to moderate acidic sourness, and medium to high hop bitterness.  Dry, coffee-like finish from roasted grains.  May have a bittersweet or unsweetened chocolate character in the palate, lasting into the finish.  Balancing factors may include some creaminess, medium-low to no fruitiness, and medium to no hop flavor.  No diacetyl.', 'Medium-light to medium-full body, with a creamy character. Low to moderate carbonation.  For the high hop bitterness and significant proportion of dark grains present, this beer is remarkably smooth.  The perception of body can be affected by the overall gravity with smaller beers being lighter in body.  May have a light astringency from the roasted grains, although harshness is undesirable.', 'A very dark, roasty, bitter, creamy ale.', 'This is the draught version of what is otherwise known as Irish stout or Irish dry stout.  Bottled versions are typically brewed from a significantly higher OG and may be designated as foreign extra stouts (if sufficiently strong).  While most commercial versions rely primarily on roasted barley as the dark grain, others use chocolate malt, black malt or combinations of the three.  The level of bitterness is somewhat variable, as is the roasted character and the dryness of the finish; allow for interpretation by brewers.', 'The dryness comes from the use of roasted unmalted barley in addition to pale malt, moderate to high hop bitterness, and good attenuation.  Flaked unmalted barley may also be used to add creaminess. A small percentage (perhaps 3%) of soured beer is sometimes added for complexity (generally by Guinness only).  Water typically has moderate carbonate hardness, although high levels will not give the classic dry finish.', 1.03600000000000003, 1.05000000000000004, 1.0069999999999999, 1.0109999999999999, 30, 45, 25, 40, 4, 5, 'Guinness Draught Stout (also canned), Murphy''s Stout, Beamish Stout, O''Hara''s Celtic Stout, Russian River O.V.L. Stout, Three Floyd''s Black Sun Stout, Dorothy Goodbody''s Wholesome Stout, Orkney Dragonhead Stout, Old Dominion Stout, Goose Island Dublin Stout, Brooklyn Dry Stout');
INSERT INTO "BjcpStyle" VALUES ('beer', 13, 'Stout', '13B', 'Sweet Stout', 'Mild roasted grain aroma, sometimes with coffee and/or chocolate notes.  An impression of cream-like sweetness often exists.  Fruitiness can be low to moderately high.  Diacetyl low to none.  Hop aroma low to none.', 'Very dark brown to black in color.  Can be opaque (if not, it should be clear).  Creamy tan to brown head.', 'Dark roasted grains and malts dominate the flavor as in dry stout, and provide coffee and/or chocolate flavors.  Hop bitterness is moderate (lower than in dry stout).  Medium to high sweetness (often from the addition of lactose) provides a counterpoint to the roasted character and hop bitterness, and lasts into the finish.  Low to moderate fruity esters.  Diacetyl low to none.  The balance between dark grains/malts and sweetness can vary, from quite sweet to moderately dry and somewhat roasty.', 'Medium-full to full-bodied and creamy.  Low to moderate carbonation.  High residual sweetness from unfermented sugars enhances the full-tasting mouthfeel.', 'A very dark, sweet, full-bodied, slightly roasty ale.  Often tastes like sweetened espresso.', 'Gravities are low in England, higher in exported and US products.  Variations exist, with the level of residual sweetness, the intensity of the roast character, and the balance between the two being the variables most subject to interpretation.', 'The sweetness in most Sweet Stouts comes from a lower bitterness level than dry stouts and a high percentage of unfermentable dextrins.   Lactose, an unfermentable sugar, is frequently added to provide additional residual sweetness.  Base of pale malt, and may use roasted barley, black malt, chocolate malt, crystal malt, and adjuncts such as maize or treacle.  High carbonate water is common.', 1.04400000000000004, 1.06000000000000005, 1.01200000000000001, 1.02400000000000002, 20, 40, 30, 40, 4, 6, 'Mackeson''s XXX Stout, Watney''s Cream Stout, Farson''s Lacto Stout, St. Peter''s Cream Stout, Marston''s Oyster Stout, Sheaf Stout, Hitachino Nest Sweet Stout (Lacto), Samuel Adams Cream Stout, Left Hand Milk Stout, Widmer Snowplow Milk Stout');
INSERT INTO "BjcpStyle" VALUES ('beer', 13, 'Stout', '13C', 'Oatmeal Stout', 'Mild roasted grain aromas, often with a coffee-like character.  A light sweetness can imply a coffee-and-cream impression.  Fruitiness should be low to medium. Diacetyl medium-low to none.  Hop aroma low to none (UK varieties most common).  A light oatmeal aroma is optional.', 'Medium brown to black in color.  Thick, creamy, persistent tan- to brown-colored head.  Can be opaque (if not, it should be clear).', 'Medium sweet to medium dry palate, with the complexity of oats and dark roasted grains present.  Oats can add a nutty, grainy or earthy flavor.  Dark grains can combine with malt sweetness to give the impression of milk chocolate or coffee with cream.  Medium hop bitterness with the balance toward malt.  Diacetyl medium-low to none.  Hop flavor medium-low to none.', 'Medium-full to full body, smooth, silky, sometimes an almost oily slickness from the oatmeal.  Creamy. Medium to medium-high carbonation.', 'A very dark, full-bodied, roasty, malty ale with a complementary oatmeal flavor.', 'Generally between sweet and dry stouts in sweetness.  Variations exist, from fairly sweet to quite dry.  The level of bitterness also varies, as does the oatmeal impression.  Light use of oatmeal may give a certain silkiness of body and richness of flavor, while heavy use of oatmeal can be fairly intense in flavor with an almost oily mouthfeel.  When judging, allow for differences in interpretation.', 'Pale, caramel and dark roasted malts and grains.', 1.04800000000000004, 1.06499999999999995, 1.01000000000000001, 1.01800000000000002, 25, 40, 22, 40, 4.20000000000000018, 5.90000000000000036, 'Samuel Smith Oatmeal Stout, Young''s Oatmeal Stout, McAuslan Oatmeal Stout, Maclay''s Oat Malt Stout, Broughton Kinmount Willie Oatmeal Stout, Anderson Valley Barney Flats Oatmeal Stout, TrÃ¶egs Oatmeal Stout, New Holland The Poet, Goose Island Oatmeal Stout, Wolaver''s Oatmeal Stout');
INSERT INTO "BjcpStyle" VALUES ('beer', 13, 'Stout', '13D', 'Foreign Extra Stout', 'Roasted grain aromas moderate to high, and can have coffee, chocolate and/or lightly burnt notes.  Fruitiness medium to high.  Some versions may have a sweet aroma, or molasses, licorice, dried fruit, and/or vinous aromatics.  Stronger versions can have the aroma of alcohol (never sharp, hot, or solventy).  Hop aroma low to none.  Diacetyl low to none.', 'Very deep brown to black in color.  Clarity usually obscured by deep color (if not opaque, should be clear).  Large tan to brown head with good retention.', 'Tropical versions can be quite sweet without much roast or bitterness, while export versions can be moderately dry (reflecting impression of a scaled-up version of either sweet stout or dry stout).  Roasted grain and malt character can be moderate to high, although sharpness of dry stout will not be present in any example.  Tropical versions can have high fruity esters, smooth dark grain flavors, and restrained bitterness; they often have a sweet, rum-like quality.  Export versions tend to have lower esters, more assertive roast flavors, and higher bitterness.  The roasted flavors of either version may taste of coffee, chocolate, or lightly burnt grain.  Little to no hop flavor.  Very low to no diacetyl.', 'Medium-full to full body, often with a smooth, creamy character.  May give a warming (but never hot) impression from alcohol presence.  Moderate to moderately-high carbonation.', 'A very dark, moderately strong, roasty ale.  Tropical varieties can be quite sweet, while export versions can be drier and fairly robust.', 'A rather broad class of stouts, these can be either fruity and sweet, dry and bitter, or even tinged with Brettanomyces (e.g., Guinness Foreign Extra Stout; this type of beer is best entered as a Specialty Beer â€“ Category 23).  Think of the style as either a scaled-up dry and/or sweet stout, or a scaled-down Imperial stout without the late hops.  Highly bitter and hoppy versions are best entered as American-style Stouts (13E).', 'Similar to dry or sweet stout, but with more gravity.  Pale and dark roasted malts and grains.  Hops mostly for bitterness.  May use adjuncts and sugar to boost gravity.  Ale yeast (although some tropical stouts are brewed with lager yeast).', 1.05600000000000005, 1.07499999999999996, 1.01000000000000001, 1.01800000000000002, 30, 70, 30, 40, 5.5, 8, 'Lion Stout (Sri Lanka), Dragon Stout (Jamaica), ABC Stout (Singapore), Royal Extra "The Lion Stout" (Trinidad), Jamaica Stout (Jamaica), Export-Type: Freeminer Deep Shaft Stout, Guinness Foreign Extra Stout (bottled, not sold in the US), Ridgeway of Oxfordshire Foreign Extra Stout, Coopers Best Extra Stout, Elysian Dragonstooth Stout');
INSERT INTO "BjcpStyle" VALUES ('beer', 13, 'Stout', '13E', 'American Stout', 'Moderate to strong aroma of roasted malts, often having a roasted coffee or dark chocolate quality.  Burnt or charcoal aromas are low to none.  Medium to very low hop aroma, often with a citrusy or resiny American hop character.  Esters are optional, but can be present up to medium intensity.  Light alcohol-derived aromatics are also optional.  No diacetyl.', 'Generally a jet black color, although some may appear very dark brown.  Large, persistent head of light tan to light brown in color.  Usually opaque.', 'Moderate to very high roasted malt flavors, often tasting of coffee, roasted coffee beans, dark or bittersweet chocolate.  May have a slightly burnt coffee ground flavor, but this character should not be prominent if present.  Low to medium malt sweetness, often with rich chocolate or caramel flavors.  Medium to high bitterness.  Hop flavor can be low to high, and generally reflects citrusy or resiny American varieties.  Light esters may be present but are not required.  Medium to dry finish, occasionally with a light burnt quality.  Alcohol flavors can be present up to medium levels, but smooth.  No diacetyl.', 'Medium to full body.  Can be somewhat creamy, particularly if a small amount of oats have been used to enhance mouthfeel.  Can have a bit of roast-derived astringency, but this character should not be excessive.  Medium-high to high carbonation.  Light to moderately strong alcohol warmth, but smooth and not excessively hot.', 'A hoppy, bitter, strongly roasted Foreign-style Stout (of the export variety).', 'Breweries express individuality through varying the roasted malt profile, malt sweetness and flavor, and the amount of finishing hops used.  Generally has bolder roasted malt flavors and hopping than other traditional stouts (except Imperial Stouts).', 'Common American base malts and yeast.  Varied use of dark and roasted malts, as well as caramel-type malts.  Adjuncts such as oatmeal may be present in low quantities.  American hop varieties.', 1.05000000000000004, 1.07499999999999996, 1.01000000000000001, 1.02200000000000002, 35, 75, 30, 40, 5, 7, 'Rogue Shakespeare Stout, Deschutes Obsidian Stout, Sierra Nevada Stout, North Coast Old No. 38, Bar Harbor Cadillac Mountain Stout, Avery Out of Bounds Stout, Lost Coast 8 Ball Stout, Mad River Steelhead Extra Stout');
INSERT INTO "BjcpStyle" VALUES ('beer', 13, 'Stout', '13F', 'Russian Imperial Stout', 'Rich and complex, with variable amounts of roasted grains, maltiness, fruity esters, hops, and alcohol.  The roasted malt character can take on coffee, dark chocolate, or slightly burnt tones and can be light to moderately strong.  The malt aroma can be subtle to rich and barleywine-like, depending on the gravity and grain bill.  May optionally show a slight specialty malt character (e.g., caramel), but this should only add complexity and not dominate.  Fruity esters may be low to moderately strong, and may take on a complex, dark fruit (e.g., plums, prunes, raisins) character.  Hop aroma can be very low to quite aggressive, and may contain any hop variety.  An alcohol character may be present, but shouldn''t be sharp, hot or solventy.  Aged versions may have a slight vinous or port-like quality, but shouldn''t be sour.  No diacetyl.  The balance can vary with any of the aroma elements taking center stage.  Not all possible aromas described need be present; many interpretations are possible.  Aging affects the intensity, balance and smoothness of aromatics.', 'Color may range from very dark reddish-brown to jet black. Opaque.  Deep tan to dark brown head.  Generally has a well-formed head, although head retention may be low to moderate.  High alcohol and viscosity may be visible in "legs" when beer is swirled in a glass.', 'Rich, deep, complex and frequently quite intense, with variable amounts of roasted malt/grains, maltiness, fruity esters, hop bitterness and flavor, and alcohol.  Medium to aggressively high bitterness.  Medium-low to high hop flavor (any variety).  Moderate to aggressively high roasted malt/grain flavors can suggest bittersweet or unsweetened chocolate, cocoa, and/or strong coffee.  A slightly burnt grain, burnt currant or tarry character may be evident.  Fruity esters may be low to intense, and can take on a dark fruit character (raisins, plums, or prunes).  Malt backbone can be balanced and supportive to rich and barleywine-like, and may optionally show some supporting caramel, bready or toasty flavors.  Alcohol strength should be evident, but not hot, sharp, or solventy.  No diacetyl.  The palate and finish can vary from relatively dry to moderately sweet, usually with some lingering roastiness, hop bitterness and warming character.  The balance and intensity of flavors can be affected by aging, with some flavors becoming more subdued over time and some aged, vinous or port-like qualities developing.', 'Full to very full-bodied and chewy, with a velvety, luscious texture (although the body may decline with long conditioning).  Gentle smooth warmth from alcohol should be present and noticeable.  Should not be syrupy and under-attenuated.  Carbonation may be low to moderate, depending on age and conditioning.', 'An intensely flavored, big, dark ale. Roasty, fruity, and bittersweet, with a noticeable alcohol presence. Dark fruit flavors meld with roasty, burnt, or almost tar-like sensations.  Like a black barleywine with every dimension of flavor coming into play.', 'Variations exist, with English and American interpretations (predictably, the American versions have more bitterness, roasted character, and finishing hops, while the English varieties reflect a more complex specialty malt character and a more forward ester profile).  The wide range of allowable characteristics allow for maximum brewer creativity.', 'Well-modified pale malt, with generous quantities of roasted malts and/or grain.  May have a complex grain bill using virtually any variety of malt.  Any type of hops may be used.  Alkaline water balances the abundance of acidic roasted grain in the grist.  American or English ale yeast.', 1.07499999999999996, 1.11499999999999999, 1.01800000000000002, 1.03000000000000003, 50, 90, 30, 40, 8, 12, 'Three Floyd''s Dark Lord, Bell''s Expedition Stout, North Coast Old Rasputin Imperial Stout, Stone Imperial Stout, Samuel Smith Imperial Stout, Scotch Irish Tsarina Katarina Imperial Stout, Thirsty Dog Siberian Night, Deschutes The Abyss, Great Divide Yeti, Southampton Russian Imperial Stout, Rogue Imperial Stout, Bear Republic Big Bear Black Stout, Great Lakes Blackout Stout, Avery The Czar, Founders Imperial Stout, Victory Storm King, Brooklyn Black Chocolate Stout');
INSERT INTO "BjcpStyle" VALUES ('beer', 14, 'India Pale Ale(IPA)', '14A', 'English IPA', 'A moderate to moderately high hop aroma of floral, earthy or fruity nature is typical, although the intensity of hop character is usually lower than American versions.  A slightly grassy dry-hop aroma is acceptable, but not required.  A moderate caramel-like or toasty malt presence is common.  Low to moderate fruitiness, either from esters or hops, can be present.  Some versions may have a sulfury note, although this character is not mandatory.', 'Color ranges from golden amber to light copper, but most are pale to medium amber with an orange-ish tint.  Should be clear, although unfiltered dry-hopped versions may be a bit hazy.  Good head stand with off-white color should persist.', 'Hop flavor is medium to high, with a moderate to assertive hop bitterness.  The hop flavor should be similar to the aroma (floral, earthy, fruity, and/or slightly grassy).  Malt flavor should be medium-low to medium-high, but should be noticeable, pleasant, and support the hop aspect.  The malt should show an English character and be somewhat bready, biscuit-like, toasty, toffee-like and/or caramelly.  Despite the substantial hop character typical of these beers, sufficient malt flavor, body and complexity to support the hops will provide the best balance. Very low levels of diacetyl are acceptable, and fruitiness from the fermentation or hops adds to the overall complexity.  Finish is medium to dry, and bitterness may linger into the aftertaste but should not be harsh.  If high sulfate water is used, a distinctively minerally, dry finish, some sulfur flavor, and a lingering bitterness are usually present.  Some clean alcohol flavor can be noted in stronger versions.  Oak is inappropriate in this style.', 'Smooth, medium-light to medium-bodied mouthfeel without hop-derived astringency, although moderate to medium-high carbonation can combine to render an overall dry sensation in the presence of malt sweetness.  Some smooth alcohol warming can and should be sensed in stronger (but not all) versions.', 'A hoppy, moderately strong pale ale that features characteristics consistent with the use of English malt, hops and yeast.  Has less hop character and a more pronounced malt flavor than American versions.', 'A pale ale brewed to an increased gravity and hop rate.  Modern versions of English IPAs generally pale in comparison (pun intended) to their ancestors.  The term "IPA" is loosely applied in commercial English beers today, and has been (incorrectly) used in beers below 4% ABV.  Generally will have more finish hops and less fruitiness and/or caramel than English pale ales and bitters.  Fresher versions will obviously have a more significant finishing hop character.', 'Pale ale malt (well-modified and suitable for single-temperature infusion mashing); English hops; English yeast that can give a fruity or sulfury/minerally profile. Refined sugar may be used in some versions.  High sulfate and low carbonate water is essential to achieving a pleasant hop bitterness in authentic Burton versions, although not all examples will exhibit the strong sulfate character.', 1.05000000000000004, 1.07499999999999996, 1.01000000000000001, 1.01800000000000002, 40, 60, 8, 14, 5, 7.5, 'Meantime India Pale Ale, Freeminer Trafalgar IPA, Fuller''s IPA, Ridgeway Bad Elf, Summit India Pale Ale, Samuel Smith''s India Ale, Hampshire Pride of Romsey IPA, Burton Bridge Empire IPA,Middle Ages ImPailed Ale, Goose Island IPA, Brooklyn East India Pale Ale');
INSERT INTO "BjcpStyle" VALUES ('beer', 16, 'Belgian and French Ale', '16C', 'Saison', 'High fruitiness with low to moderate hop aroma and moderate to no herb, spice and alcohol aroma.  Fruity esters dominate the aroma and are often reminiscent of citrus fruits such as oranges or lemons.  A low to medium-high spicy or floral hop aroma is usually present.  A moderate spice aroma (from actual spice additions and/or yeast-derived phenols) complements the other aromatics.  When phenolics are present they tend to be peppery rather than clove-like.  A low to moderate sourness or acidity may be present, but should not overwhelm other characteristics.  Spice, hop and sour aromatics typically increase with the strength of the beer.  Alcohols are soft, spicy and low in intensity, and should not be hot or solventy.  The malt character is light.  No diacetyl.', 'Often a distinctive pale orange but may be golden or amber in color.  There is no correlation between strength and color.  Long-lasting, dense, rocky white to ivory head resulting in characteristic "Belgian lace" on the glass as it fades.  Clarity is poor to good though haze is not unexpected in this type of unfiltered farmhouse beer.  Effervescent.', 'Combination of fruity and spicy flavors supported by a soft malt character, a low to moderate alcohol presence and tart sourness.  Extremely high attenuation gives a characteristic dry finish.  The fruitiness is frequently citrusy (orange- or lemon-like).  The addition of one of more spices serve to add complexity, but shouldn''t dominate in the balance.  Low peppery yeast-derived phenols may be present instead of or in addition to spice additions; phenols tend to be lower than in many other Belgian beers, and complement the bitterness.  Hop flavor is low to moderate, and is generally spicy or earthy in character.  Hop bitterness may be moderate to high, but should not overwhelm fruity esters, spices, and malt.  Malt character is light but provides a sufficient background for the other flavors.  A low to moderate tart sourness may be present, but should not overwhelm other flavors.  Spices, hop bitterness and flavor, and sourness commonly increase with the strength of the beer while sweetness decreases.  No hot alcohol or solventy character.  High carbonation, moderately sulfate water, and high attenuation give a very dry finish with a long, bitter, sometimes spicy aftertaste.  The perceived bitterness is often higher than the IBU level would suggest.  No diacetyl.', 'Light to medium body.  Alcohol level can be medium to medium-high, though the warming character is low to medium.  No hot alcohol or solventy character.  Very high carbonation with an effervescent quality.  There is enough prickly acidity on the tongue to balance the very dry finish.  A low to moderate tart character may be present but should be refreshing and not to the point of puckering.', 'A refreshing, medium to strong fruity/spicy ale with a distinctive yellow-orange color, highly carbonated, well hopped, and dry with a quenching acidity.', 'Varying strength examples exist (table beers of about 5% strength, typical export beers of about 6.5%, and stronger versions of 8%+).  Strong versions (6.5%-9.5%) and darker versions (copper to dark brown/black) should be entered as Belgian Specialty Ales (16E).  Sweetness decreases and spice, hop and sour character increases with strength.  Herb and spice additions often reflect the indigenous varieties available at the brewery.  High carbonation and extreme attenuation (85-95%) helps bring out the many flavors and to increase the perception of a dry finish.  All of these beers share somewhat higher levels of acidity than other Belgian styles while the optional sour flavor is often a variable house character of a particular brewery.', 'Pilsner malt dominates the grist though a portion of Vienna and/or Munich malt contributes color and complexity.  Sometimes contains other grains such as wheat and spelt.  Adjuncts such as sugar and honey can also serve to add complexity and thin the body.  Hop bitterness and flavor may be more noticeable than in many other Belgian styles.  A saison is sometimes dry-hopped.  Noble hops, Styrian or East Kent Goldings are commonly used.  A wide variety of herbs and spices are often used to add complexity and uniqueness in the stronger versions, but should always meld well with the yeast and hop character.  Varying degrees of acidity and/or sourness can be created by the use of gypsum, acidulated malt, a sour mash or Lactobacillus.  Hard water, common to most of Wallonia, can accentuate the bitterness and dry finish.', 1.04800000000000004, 1.06499999999999995, 1.002, 1.01200000000000001, 20, 35, 5, 14, 5, 7, 'Saison Dupont Vieille Provision; FantÃ´me Saison D''ErezÃ©e - Printemps; Saison de Pipaix; Saison Regal; Saison Voisin; Lefebvre Saison 1900; Ellezelloise Saison 2000; Saison Silly; Southampton Saison; New Belgium Saison; Pizza Port SPF 45; Lost Abbey Red Barn Ale; Ommegang Hennepin');
INSERT INTO "BjcpStyle" VALUES ('beer', 14, 'India Pale Ale(IPA)', '14B', 'American IPA', 'A prominent to intense hop aroma with a citrusy, floral, perfume-like, resinous, piney, and/or fruity character derived from American hops.  Many versions are dry hopped and can have an additional grassy aroma, although this is not required.  Some clean malty sweetness may be found in the background, but should be at a lower level than in English examples.  Fruitiness, either from esters or hops, may also be detected in some versions, although a neutral fermentation character is also acceptable.  Some alcohol may be noted.', 'Color ranges from medium gold to medium reddish copper; some versions can have an orange-ish tint.  Should be clear, although unfiltered dry-hopped versions may be a bit hazy.  Good head stand with white to off-white color should persist.', 'Hop flavor is medium to high, and should reflect an American hop character with citrusy, floral, resinous, piney or fruity aspects.  Medium-high to very high hop bitterness, although the malt backbone will support the strong hop character and provide the best balance.  Malt flavor should be low to medium, and is generally clean and malty sweet although some caramel or toasty flavors are acceptable at low levels. No diacetyl.  Low fruitiness is acceptable but not required.  The bitterness may linger into the aftertaste but should not be harsh.  Medium-dry to dry finish.  Some clean alcohol flavor can be noted in stronger versions.  Oak is inappropriate in this style.  May be slightly sulfury, but most examples do not exhibit this character.', 'Smooth, medium-light to medium-bodied mouthfeel without hop-derived astringency, although moderate to medium-high carbonation can combine to render an overall dry sensation in the presence of malt sweetness.  Some smooth alcohol warming can and should be sensed in stronger (but not all) versions.  Body is generally less than in English counterparts.', 'A decidedly hoppy and bitter, moderately strong American pale ale.', '', 'Pale ale malt (well-modified and suitable for single-temperature infusion mashing); American hops; American yeast that can give a clean or slightly fruity profile. Generally all-malt, but mashed at lower temperatures for high attenuation.  Water character varies from soft to moderately sulfate.  Versions with a noticeable Rye character ("RyePA") should be entered in the Specialty category.', 1.05600000000000005, 1.07499999999999996, 1.01000000000000001, 1.01800000000000002, 40, 70, 6, 15, 5.5, 7.5, 'Bell''s Two-Hearted Ale, AleSmith IPA, Russian River Blind Pig IPA, Stone IPA, Three Floyds Alpha King, Great Divide Titan IPA, Bear Republic Racer 5 IPA, Victory Hop Devil, Sierra Nevada Celebration Ale, Anderson Valley Hop Ottin'',  Dogfish Head 60 Minute IPA, Founder''s Centennial IPA, Anchor Liberty Ale, Harpoon IPA, Avery IPA');
INSERT INTO "BjcpStyle" VALUES ('beer', 14, 'India Pale Ale(IPA)', '14C', 'Imperial IPA', 'A prominent to intense hop aroma that can be derived from American, English and/or noble varieties (although a citrusy hop character is almost always present).  Most versions are dry hopped and can have an additional resinous or grassy aroma, although this is not absolutely required.  Some clean malty sweetness may be found in the background.  Fruitiness, either from esters or hops, may also be detected in some versions, although a neutral fermentation character is typical.  Some alcohol can usually be noted, but it should not have a "hot" character.', 'Color ranges from golden amber to medium reddish copper; some versions can have an orange-ish tint.  Should be clear, although unfiltered dry-hopped versions may be a bit hazy.  Good head stand with off-white color should persist.', 'Hop flavor is strong and complex, and can reflect the use of American, English and/or noble hop varieties.  High to absurdly high hop bitterness, although the malt backbone will generally support the strong hop character and provide the best balance.  Malt flavor should be low to medium, and is generally clean and malty although some caramel or toasty flavors are acceptable at low levels. No diacetyl.  Low fruitiness is acceptable but not required.  A long, lingering bitterness is usually present in the aftertaste but should not be harsh.  Medium-dry to dry finish.  A clean, smooth alcohol flavor is usually present.  Oak is inappropriate in this style.  May be slightly sulfury, but most examples do not exhibit this character.', 'Smooth, medium-light to medium body.  No harsh hop-derived astringency, although moderate to medium-high carbonation can combine to render an overall dry sensation in the presence of malt sweetness.  Smooth alcohol warming.', 'An intensely hoppy, very strong pale ale without the big maltiness and/or deeper malt flavors of an American barleywine.  Strongly hopped, but clean, lacking harshness, and a tribute to historical IPAs.  Drinkability is an important characteristic; this should not be a heavy, sipping beer.  It should also not have much residual sweetness or a heavy character grain profile.', 'Bigger than either an English or American IPA in both alcohol strength and overall hop level (bittering and finish).  Less malty, lower body, less rich and a greater overall hop intensity than an American Barleywine.  Typically not as high in gravity/alcohol as a barleywine, since high alcohol and malt tend to limit drinkability.  A showcase for hops.', 'Pale ale malt (well-modified and suitable for single-temperature infusion mashing); can use a complex variety of hops (English, American, noble). American yeast that can give a clean or slightly fruity profile. Generally all-malt, but mashed at lower temperatures for high attenuation.  Water character varies from soft to moderately sulfate.', 1.07000000000000006, 1.09000000000000008, 1.01000000000000001, 1.02000000000000002, 60, 120, 8, 15, 7.5, 10, 'Russian River Pliny the Elder, Three Floyd''s Dreadnaught, Avery Majaraja, Bell''s Hop Slam, Stone Ruination IPA, Great Divide Hercules Double IPA, Surly Furious, Rogue I2PA, Moylan''s Hopsickle Imperial India Pale Ale, Stoudt''s Double IPA, Dogfish Head 90-minute IPA, Victory Hop Wallop');
INSERT INTO "BjcpStyle" VALUES ('beer', 15, 'German Wheat and Rye Beer', '15A', 'Weizen/Weissbier', 'Moderate to strong phenols (usually clove) and fruity esters (usually banana).  The balance and intensity of the phenol and ester components can vary but the best examples are reasonably balanced and fairly prominent.  Noble hop character ranges from low to none.  A light to moderate wheat aroma (which might be perceived as bready or grainy) may be present but other malt characteristics should not.  No diacetyl or DMS.  Optional, but acceptable, aromatics can include a light, citrusy tartness, a light to moderate vanilla character, and/or a low bubblegum aroma.  None of these optional characteristics should be high or dominant, but often can add to the complexity and balance.', 'Pale straw to very dark gold in color.  A very thick, moussy, long-lasting white head is characteristic.  The high protein content of wheat impairs clarity in an unfiltered beer, although the level of haze is somewhat variable.  A beer "mit hefe" is also cloudy from suspended yeast sediment (which should be roused before drinking).  The filtered Krystal version has no yeast and is brilliantly clear.', 'Low to moderately strong banana and clove flavor.  The balance and intensity of the phenol and ester components can vary but the best examples are reasonably balanced and fairly prominent.  Optionally, a very light to moderate vanilla character and/or low bubblegum notes can accentuate the banana flavor, sweetness and roundness; neither should be dominant if present.  The soft, somewhat bready or grainy flavor of wheat is complementary, as is a slightly sweet Pils malt character.  Hop flavor is very low to none, and hop bitterness is very low to moderately low.  A tart, citrusy character from yeast and high carbonation is often present.  Well rounded, flavorful palate with a relatively dry finish.  No diacetyl or DMS.', 'Medium-light to medium body; never heavy.  Suspended yeast may increase the perception of body.  The texture of wheat imparts the sensation of a fluffy, creamy fullness that may progress to a light, spritzy finish aided by high carbonation.  Always effervescent.', 'A pale, spicy, fruity, refreshing wheat-based ale.', 'These are refreshing, fast-maturing beers that are lightly hopped and show a unique banana-and-clove yeast character. These beers often don''t age well and are best enjoyed while young and fresh.  The version "mit hefe" is served with yeast sediment stirred in; the krystal version is filtered for excellent clarity.  Bottles with yeast are traditionally swirled or gently rolled prior to serving.  The character of a krystal weizen is generally fruitier and less phenolic than that of the hefe-weizen.', 'By German law, at least 50% of the grist must be malted wheat, although some versions use up to 70%; the remainder is Pilsner malt.  A traditional decoction mash gives the appropriate body without cloying sweetness.  Weizen ale yeasts produce the typical spicy and fruity character, although extreme fermentation temperatures can affect the balance and produce off-flavors.  A small amount of noble hops are used only for bitterness.', 1.04400000000000004, 1.05200000000000005, 1.01000000000000001, 1.01400000000000001, 8, 15, 2, 8, 4.29999999999999982, 5.59999999999999964, 'Weihenstephaner Hefeweissbier, Schneider Weisse Weizenhell, Paulaner Hefe-Weizen, Hacker-Pschorr Weisse, Plank Bavarian Hefeweizen, Ayinger BrÃ¤u Weisse, Ettaler Weissbier Hell, Franziskaner Hefe-Weisse, Andechser Weissbier HefetrÃ¼b, Kapuziner Weissbier, Erdinger Weissbier, Penn Weizen, Barrelhouse Hocking Hills HefeWeizen, Eisenbahn Weizenbier');
INSERT INTO "BjcpStyle" VALUES ('beer', 15, 'German Wheat and Rye Beer', '15B', 'Dunkelweizen', 'Moderate to strong phenols (usually clove) and fruity esters (usually banana).  The balance and intensity of the phenol and ester components can vary but the best examples are reasonably balanced and fairly prominent.  Optionally, a low to moderate vanilla character and/or low bubblegum notes may be present, but should not dominate.  Noble hop character ranges from low to none.  A light to moderate wheat aroma (which might be perceived as bready or grainy) may be present and is often accompanied by a caramel, bread crust, or richer malt aroma (e.g., from Vienna and/or Munich malt).  Any malt character is supportive and does not overpower the yeast character.  No diacetyl or DMS.  A light tartness is optional but acceptable.', 'Light copper to mahogany brown in color.  A very thick, moussy, long-lasting off-white head is characteristic.  The high protein content of wheat impairs clarity in this traditionally unfiltered style, although the level of haze is somewhat variable.  The suspended yeast sediment (which should be roused before drinking) also contributes to the cloudiness.', 'Low to moderately strong banana and clove flavor.  The balance and intensity of the phenol and ester components can vary but the best examples are reasonably balanced and fairly prominent.    Optionally, a very light to moderate vanilla character and/or low bubblegum notes can accentuate the banana flavor, sweetness and roundness; neither should be dominant if present. The soft, somewhat bready or grainy flavor of wheat is complementary, as is a richer caramel and/or melanoidin character from Munich and/or Vienna malt.  The malty richness can be low to medium-high, but shouldn''t overpower the yeast character.  A roasted malt character is inappropriate.  Hop flavor is very low to none, and hop bitterness is very low to low.  A tart, citrusy character from yeast and high carbonation is sometimes present, but typically muted.  Well rounded, flavorful, often somewhat sweet palate with a relatively dry finish.  No diacetyl or DMS.', 'Medium-light to medium-full body.  The texture of wheat as well as yeast in suspension imparts the sensation of a fluffy, creamy fullness that may progress to a lighter finish, aided by moderate to high carbonation.  The presence of Munich and/or Vienna malts also provide an additional sense of richness and fullness.  Effervescent.', 'A moderately dark, spicy, fruity, malty, refreshing wheat-based ale.  Reflecting the best yeast and wheat character of a hefeweizen blended with the malty richness of a Munich dunkel.', 'The presence of Munich and/or Vienna-type barley malts gives this style a deep, rich barley malt character not found in a hefeweizen.  Bottles with yeast are traditionally swirled or gently rolled prior to serving. ', 'By German law, at least 50% of the grist must be malted wheat, although some versions use up to 70%; the remainder is usually Munich and/or Vienna malt.  A traditional decoction mash gives the appropriate body without cloying sweetness.  Weizen ale yeasts produce the typical spicy and fruity character, although extreme fermentation temperatures can affect the balance and produce off-flavors.  A small amount of noble hops are used only for bitterness.', 1.04400000000000004, 1.05600000000000005, 1.01000000000000001, 1.01400000000000001, 10, 18, 14, 23, 4.29999999999999982, 5.59999999999999964, 'Weihenstephaner Hefeweissbier Dunkel, Ayinger Ur-Weisse, Franziskaner Dunkel Hefe-Weisse, Schneider Weisse (Original), Ettaler Weissbier Dunkel, Hacker-Pschorr Weisse Dark, Tucher Dunkles Hefe Weizen, Edelweiss Dunkel Weissbier, Erdinger Weissbier Dunkel, Kapuziner Weissbier Schwarz');
INSERT INTO "BjcpStyle" VALUES ('beer', 15, 'German Wheat and Rye Beer', '15C', 'Weizenbock', 'Rich, bock-like melanoidins and bready malt combined with a powerful aroma of dark fruit (plums, prunes, raisins or grapes).  Moderate to strong phenols (most commonly vanilla and/or clove) add complexity, and some banana esters may also be present.  A moderate aroma of alcohol is common, although never solventy.  No hop aroma, diacetyl or DMS.', 'Dark amber to dark, ruby brown in color.  A very thick, moussy, long-lasting light tan head is characteristic.  The high protein content of wheat impairs clarity in this traditionally unfiltered style, although the level of haze is somewhat variable.  The suspended yeast sediment (which should be roused before drinking) also contributes to the cloudiness.', 'A complex marriage of rich, bock-like melanoidins, dark fruit, spicy clove-like phenols, light banana and/or vanilla, and a moderate wheat flavor.  The malty, bready flavor of wheat is further enhanced by the copious use of Munich and/or Vienna malts.  May have a slightly sweet palate, and a light chocolate character is sometimes found (although a roasted character is inappropriate).  A faintly tart character may optionally be present.  Hop flavor is absent, and hop bitterness is low.  The wheat, malt, and yeast character dominate the palate, and the alcohol helps balance the finish. Well-aged examples may show some sherry-like oxidation as a point of complexity.  No diacetyl or DMS.', 'Medium-full to full body.  A creamy sensation is typical, as is the warming sensation of substantial alcohol content.  The presence of Munich and/or Vienna malts also provide an additional sense of richness and fullness.  Moderate to high carbonation.  Never hot or solventy.', 'A strong, malty, fruity, wheat-based ale combining the best flavors of a dunkelweizen and the rich strength and body of a bock.', 'A dunkel-weizen beer brewed to bock or doppelbock strength.  Now also made in the Eisbock style as a specialty beer.  Bottles may be gently rolled or swirled prior to serving to rouse the yeast.', 'A high percentage of malted wheat is used (by German law must be at least 50%, although it may contain up to 70%), with the remainder being Munich- and/or Vienna-type barley malts.  A traditional decoction mash gives the appropriate body without cloying sweetness.  Weizen ale yeasts produce the typical spicy and fruity character.  Too warm or too cold fermentation will cause the phenols and esters to be out of balance and may create off-flavors.  A small amount of noble hops are used only for bitterness.', 1.06400000000000006, 1.09000000000000008, 1.0149999999999999, 1.02200000000000002, 15, 30, 12, 25, 6.5, 8, 'Schneider Aventinus, Schneider Aventinus Eisbock, Plank Bavarian Dunkler Weizenbock, Plank Bavarian Heller Weizenbock, AleSmith Weizenbock, Erdinger Pikantus, Mahr''s Der Weisse Bock, Victory Moonglow Weizenbock, High Point Ramstein Winter Wheat, Capital Weizen Doppelbock, Eisenbahn Vigorosa');
INSERT INTO "BjcpStyle" VALUES ('beer', 15, 'German Wheat and Rye Beer', '15D', 'Roggenbier (German Rye Beer)', 'Light to moderate spicy rye aroma intermingled with light to moderate weizen yeast aromatics (spicy clove and fruity esters, either banana or citrus).  Light noble hops are acceptable.  Can have a somewhat acidic aroma from rye and yeast.  No diacetyl.', 'Light coppery-orange to very dark reddish or coppery-brown color.  Large creamy off-white to tan head, quite dense and persistent (often thick and rocky).  Cloudy, hazy appearance.', 'Grainy, moderately-low to moderately-strong spicy rye flavor, often having a hearty flavor reminiscent of rye or pumpernickel bread.  Medium to medium-low bitterness allows an initial malt sweetness (sometimes with a bit of caramel) to be tasted before yeast and rye character takes over.  Low to moderate weizen yeast character (banana, clove, and sometimes citrus), although the balance can vary.  Medium-dry, grainy finish with a tangy, lightly bitter (from rye) aftertaste.  Low to moderate noble hop flavor acceptable, and can persist into aftertaste.  No diacetyl.', 'Medium to medium-full body.  High carbonation.  Light tartness optional.', 'A dunkelweizen made with rye rather than wheat, but with a greater body and light finishing hops.', 'American-style rye beers should be entered in the American Rye category (6D).  Other traditional beer styles with enough rye added to give a noticeable rye character should be entered in the Specialty Beer category (23).  Rye is a huskless grain and is difficult to mash, often resulting in a gummy mash texture that is prone to sticking.  Rye has been characterized as having the most assertive flavor of all cereal grains.  It is inappropriate to add caraway seeds to a roggenbier (as some American brewers do); the rye character is traditionally from the rye grain only.', 'Malted rye typically constitutes 50% or greater of the grist (some versions have 60-65% rye).  Remainder of grist can include pale malt, Munich malt, wheat malt, crystal malt and/or small amounts of debittered dark malts for color adjustment.  Weizen yeast provides distinctive banana esters and clove phenols.  Light usage of noble hops in bitterness, flavor and aroma.  Lower fermentation temperatures accentuate the clove character by suppressing ester formation.  Decoction mash commonly used (as with weizenbiers).', 1.04600000000000004, 1.05600000000000005, 1.01000000000000001, 1.01400000000000001, 10, 20, 14, 19, 4.5, 6, 'Paulaner Roggen (formerly Thurn und Taxis, no longer imported into the US), BÃ¼rgerbrÃ¤u Wolznacher Roggenbier');
INSERT INTO "BjcpStyle" VALUES ('beer', 16, 'Belgian and French Ale', '16A', 'Witbier', 'Moderate sweetness (often with light notes of honey and/or vanilla) with light, grainy, spicy wheat aromatics, often with a bit of tartness.  Moderate perfumy coriander, often with a complex herbal, spicy, or peppery note in the background.  Moderate zesty, citrusy orangey fruitiness.   A low spicy-herbal hop aroma is optional, but should never overpower the other characteristics.  No diacetyl.  Vegetal, celery-like, or ham-like aromas are inappropriate.  Spices should blend in with fruity, floral and sweet aromas and should not be overly strong.', 'Very pale straw to very light gold in color.  The beer will be very cloudy from starch haze and/or yeast, which gives it a milky, whitish-yellow appearance.  Dense, white, moussy head.  Head retention should be quite good.', 'Pleasant sweetness (often with a honey and/or vanilla character) and a zesty, orange-citrusy fruitiness.  Refreshingly crisp with a dry, often tart, finish.  Can have a low wheat flavor.  Optionally has a very light lactic-tasting sourness.  Herbal-spicy flavors, which may include coriander and other spices, are common should be subtle and balanced, not overpowering.  A spicy-earthy hop flavor is low to none, and if noticeable, never gets in the way of the spices.  Hop bitterness is low to medium-low (as with a Hefeweizen), and doesn''t interfere with refreshing flavors of fruit and spice, nor does it persist into the finish.  Bitterness from orange pith should not be present.  Vegetal, celery-like, ham-like, or soapy flavors are inappropriate.  No diacetyl.  ', 'Medium-light to medium body, often having a smoothness and light creaminess from unmalted wheat and the occasional oats.  Despite body and creaminess, finishes dry and often a bit tart.  Effervescent character from high carbonation.  Refreshing, from carbonation, light acidity, and lack of bitterness in finish.  No harshness or astringency from orange pith.  Should not be overly dry and thin, nor should it be thick and heavy.', 'A refreshing, elegant, tasty, moderate-strength wheat-based ale.', 'The presence, character and degree of spicing and lactic sourness varies.  Overly spiced and/or sour beers are not good examples of the style.  Coriander of certain origins might give an inappropriate ham or celery character. The beer tends to be fragile and does not age well, so younger, fresher, properly handled examples are most desirable.  Most examples seem to be approximately 5% ABV.', 'About 50% unmalted wheat (traditionally soft white winter wheat) and 50% pale barley malt (usually Pils malt) constitute the grist.  In some versions, up to 5-10% raw oats may be used.  Spices of freshly-ground coriander and CuraÃ§ao or sometimes sweet orange peel complement the sweet aroma and are quite characteristic.  Other spices (e.g., chamomile, cumin, cinnamon, Grains of Paradise) may be used for complexity but are much less prominent.  Ale yeast prone to the production of mild, spicy flavors is very characteristic.  In some instances a very limited lactic fermentation, or the actual addition of lactic acid, is done.', 1.04400000000000004, 1.05200000000000005, 1.00800000000000001, 1.01200000000000001, 10, 20, 2, 4, 4.5, 5.5, 'Hoegaarden Wit, St. Bernardus Blanche, Celis White, Vuuve 5, Brugs Tarwebier (Blanche de Bruges), Wittekerke, Allagash White, Blanche de Bruxelles, Ommegang Witte, Avery White Rascal, Unibroue Blanche de Chambly, Sterkens White Ale, BellÂ’s Winter White Ale, Victory Whirlwind Witbier, Hitachino Nest White Ale');
INSERT INTO "BjcpStyle" VALUES ('beer', 16, 'Belgian and French Ale', '16B', 'Belgian Pale Ale', 'Prominent aroma of malt with moderate fruity character and low hop aroma.  Toasty, biscuity malt aroma.  May have an orange- or pear-like fruitiness though not as fruity/citrusy as many other Belgian ales.  Distinctive floral or spicy, low to moderate strength hop character optionally blended with background level peppery, spicy phenols.  No diacetyl.', 'Amber to copper in color.  Clarity is very good.  Creamy, rocky, white head often fades more quickly than other Belgian beers.', 'Fruity and lightly to moderately spicy with a soft, smooth malt and relatively light hop character and low to very low phenols.  May have an orange- or pear-like fruitiness, though not as fruity/citrusy as many other Belgian ales.  Has an initial soft, malty sweetness with a toasty, biscuity, nutty malt flavor.  The hop flavor is low to none.  The hop bitterness is medium to low, and is optionally complemented by low amounts of peppery phenols.  There is a moderately dry to moderately sweet finish, with hops becoming more pronounced in those with a drier finish.', 'Medium to medium-light body.  Alcohol level is restrained, and any warming character should be low if present.  No hot alcohol or solventy character.  Medium carbonation.', 'A fruity, moderately malty, somewhat spicy, easy-drinking, copper-colored ale.', 'Most commonly found in the Flemish provinces of Antwerp and Brabant.  Considered "everyday" beers (Category I).  Compared to their higher alcohol Category S cousins, they are Belgian "session beers" for ease of drinking.  Nothing should be too pronounced or dominant; balance is the key.', 'Pilsner or pale ale malt contributes the bulk of the grist with (cara) Vienna and Munich malts adding color, body and complexity.  Sugar is not commonly used as high gravity is not desired.  Noble hops, Styrian Goldings, East Kent Goldings or Fuggles are commonly used.  Yeasts prone to moderate production of phenols are often used but fermentation temperatures should be kept moderate to limit this character.', 1.04800000000000004, 1.05400000000000005, 1.01000000000000001, 1.01400000000000001, 20, 30, 8, 14, 4.79999999999999982, 5.5, 'De Koninck, Speciale Palm, Dobble Palm, Russian River Perdition, Ginder Ale, Op-Ale, St. Pieters Zinnebir, Brewer''s Art House Pale Ale, Avery Karma, Eisenbahn Pale Ale, Ommegang Rare Vos (unusual in its 6.5% ABV strength)');
INSERT INTO "BjcpStyle" VALUES ('beer', 16, 'Belgian and French Ale', '16D', 'Bière de Garde', 'Prominent malty sweetness, often with a complex, light to moderate toasty character.  Some caramelization is acceptable.  Low to moderate esters.  Little to no hop aroma (may be a bit spicy or herbal).  Commercial versions will often have a musty, woodsy, cellar-like character that is difficult to achieve in homebrew.   Paler versions will still be malty but will lack richer, deeper aromatics and may have a bit more hops.  No diacetyl.', 'Three main variations exist (blond, amber and brown), so color can range from golden blonde to reddish-bronze to chestnut brown.  Clarity is good to poor, although haze is not unexpected in this type of often unfiltered beer.  Well-formed head, generally white to off-white (varies by beer color), supported by high carbonation.', 'Medium to high malt flavor often with a toasty, toffee-like or caramel sweetness.  Malt flavors and complexity tend to increase as beer color darkens.  Low to moderate esters and alcohol flavors.  Medium-low hop bitterness provides some support, but the balance is always tilted toward the malt.  The malt flavor lasts into the finish but the finish is medium-dry to dry, never cloying.  Alcohol can provide some additional dryness in the finish.  Low to no hop flavor, although paler versions can have slightly higher levels of herbal or spicy hop flavor (which can also come from the yeast).  Smooth, well-lagered character.  No diacetyl.', 'Medium to medium-light (lean) body, often with a smooth, silky character.  Moderate to high carbonation.  Moderate alcohol, but should be very smooth and never hot.', 'A fairly strong, malt-accentuated, lagered artisanal farmhouse beer.', 'Three main variations are included in the style: the brown (brune), the blond (blonde), and the amber (ambrÃ©e).  The darker versions will have more malt character, while the paler versions can have more hops (but still are malt-focused beers).  A related style is BiÃ¨re de Mars, which is brewed in March (Mars) for present use and will not age as well.  Attenuation rates are in the 80-85% range.  Some fuller-bodied examples exist, but these are somewhat rare.', 'The "cellar" character in commercial examples is unlikely to be duplicated in homebrews as it comes from indigenous yeasts and molds.  Commercial versions often have a "corked", dry, astringent character that is often incorrectly identified as "cellar-like."  Homebrews therefore are usually cleaner.  Base malts vary by beer color, but usually include pale, Vienna and Munich types.  Kettle caramelization tends to be used more than crystal malts, when present.  Darker versions will have richer malt complexity and sweetness from crystal-type malts.  Sugar may be used to add flavor and aid in the dry finish.  Lager or ale yeast fermented at cool ale temperatures, followed by long cold conditioning (4-6 weeks for commercial operations).  Soft water.  Floral, herbal or spicy continental hops.', 1.06000000000000005, 1.08000000000000007, 1.00800000000000001, 1.01600000000000001, 18, 28, 6, 19, 6, 8.5, 'Jenlain (amber), Jenlain BiÃ¨re de Printemps (blond), St. Amand (brown), Ch''Ti Brun (brown), Ch''Ti Blond (blond), La Choulette (all 3 versions), La Choulette BiÃ¨re des Sans Culottes (blond), Saint Sylvestre 3 Monts (blond), Biere Nouvelle (brown), Castelain (blond), Jade (amber), Brasseurs BiÃ¨re de Garde (amber), Southampton BiÃ¨re de Garde (amber), Lost Abbey Avante Garde (blond)');
INSERT INTO "BjcpStyle" VALUES ('beer', 17, 'Sour Ale', '17A', 'Berliner Weisse', 'A sharply sour, somewhat acidic character is dominant.  Can have up to a moderately fruity character.  The fruitiness may increase with age and a flowery character may develop.  A mild Brettanomyces aroma may be present.  No hop aroma, diacetyl, or DMS.', 'Very pale straw in color.  Clarity ranges from clear to somewhat hazy.  Large, dense, white head with poor retention due to high acidity and low protein and hop content.  Always effervescent.', 'Clean lactic sourness dominates and can be quite strong, although not so acidic as a lambic.  Some complementary bready or grainy wheat flavor is generally noticeable. Hop bitterness is very low.  A mild Brettanomyces character may be detected, as may a restrained fruitiness (both are optional).  No hop flavor.  No diacetyl or DMS.', 'Light body.  Very dry finish.  Very high carbonation.  No sensation of alcohol.', 'A very pale, sour, refreshing, low-alcohol wheat ale.', 'In Germany, it is classified as a Schankbier denoting a small beer of starting gravity in the range 7-8Â°P.  Often served with the addition of a shot of sugar syrups (''mit schuss'') flavored with raspberry (''himbeer'') or woodruff (''waldmeister'') or even mixed with Pils to counter the substantial sourness.  Has been described by some as the most purely refreshing beer in the world.', 'Wheat malt content is typically 50% of the grist (as with all German wheat beers) with the remainder being Pilsner malt.  A symbiotic fermentation with top-fermenting yeast and Lactobacillus delbruckii provides the sharp sourness, which may be enhanced by blending of beers of different ages during fermentation and by extended cool aging.  Hop bitterness is extremely low.  A single decoction mash with mash hopping is traditional.', 1.02800000000000002, 1.03200000000000003, 1.00299999999999989, 1.00600000000000001, 3, 8, 2, 3, 2.79999999999999982, 3.79999999999999982, 'Schultheiss Berliner Weisse, Berliner Kindl Weisse, Nodding Head Berliner Weisse, Weihenstephan 1809 (unusual in its 5% ABV), Bahnhof Berliner Style Weisse, Southampton Berliner Weisse, Bethlehem Berliner Weisse, Three Floyds Deesko');
INSERT INTO "BjcpStyle" VALUES ('beer', 17, 'Sour Ale', '17B', 'Flanders Red Ale', 'Complex fruitiness with complementary malt.  Fruitiness is high, and reminiscent of black cherries, oranges, plums or red currants.  There is often some vanilla and/or chocolate notes.  Spicy phenols can be present in low amounts for complexity.  The sour, acidic aroma ranges from complementary to intense.  No hop aroma.  Diacetyl is perceived only in very minor quantities, if at all, as a complementary aroma.', 'Deep red, burgundy to reddish-brown in color.  Good clarity.  White to very pale tan head.  Average to good head retention.', 'Intense fruitiness commonly includes plum, orange, black cherry or red currant flavors.  A mild vanilla and/or chocolate character is often present.  Spicy phenols can be present in low amounts for complexity.  Sour, acidic character ranges from complementary to intense.  Malty flavors range from complementary to prominent.  Generally as the sour character increases, the sweet character blends to more of a background flavor (and vice versa).  No hop flavor.  Restrained hop bitterness.  An acidic, tannic bitterness is often present in low to moderate amounts, and adds an aged red wine-like character with a long, dry finish.  Diacetyl is perceived only in very minor quantities, if at all, as a complementary flavor.', 'Medium bodied.  Low to medium carbonation.  Low to medium astringency, like a well-aged red wine, often with a prickly acidity.  Deceivingly light and crisp on the palate although a somewhat sweet finish is not uncommon.', 'A complex, sour, red wine-like Belgian-style ale.', 'Long aging and blending of young and well-aged beer often occurs, adding to the smoothness and complexity, though the aged product is sometimes released as a connoisseur''s beer.  Known as the Burgundy of Belgium, it is more wine-like than any other beer style.  The reddish color is a product of the malt although an extended, less-than-rolling portion of the boil may help add an attractive Burgundy hue.  Aging will also darken the beer.  The Flanders red is more acetic and the fruity flavors more reminiscent of a red wine than an Oud Bruin.  Can have an apparent attenuation of up to 98%.', 'A base of Vienna and/or Munich malts, light to medium cara-malts, and a small amount of Special B are used with up to 20% maize.  Low alpha acid continental hops are commonly used (avoid high alpha or distinctive American hops).  Saccharomyces, Lactobacillus and Brettanomyces (and acetobacter) contribute to the fermentation and eventual flavor.', 1.04800000000000004, 1.05699999999999994, 1.002, 1.01200000000000001, 10, 25, 10, 16, 4.59999999999999964, 6.5, 'Rodenbach Klassiek, Rodenbach Grand Cru, Bellegems Bruin, Duchesse de Bourgogne, New Belgium La Folie, Petrus Oud Bruin, Southampton Flanders Red Ale, Verhaege Vichtenaar, Monk''s Cafe Flanders Red Ale, New Glarus Enigma, Panil BarriquÃ©e, Mestreechs Aajt');
INSERT INTO "BjcpStyle" VALUES ('beer', 17, 'Sour Ale', '17C', 'Flanders Brown Ale/Oud Bruin', 'Complex combination of fruity esters and rich malt character.  Esters commonly reminiscent of raisins, plums, figs, dates, black cherries or prunes.  A malt character of caramel, toffee, orange, treacle or chocolate is also common.  Spicy phenols can be present in low amounts for complexity.  A sherry-like character may be present and generally denotes an aged example.  A low sour aroma may be present, and can modestly increase with age but should not grow to a noticeable acetic/vinegary character.  Hop aroma absent.  Diacetyl is perceived only in very minor quantities, if at all, as a complementary aroma.', 'Dark reddish-brown to brown in color.  Good clarity.  Average to good head retention.  Ivory to light tan head color.', 'Malty with fruity complexity and some caramelization character.  Fruitiness commonly includes dark fruits such as raisins, plums, figs, dates, black cherries or prunes.  A malt character of caramel, toffee, orange, treacle or chocolate is also common.  Spicy phenols can be present in low amounts for complexity.  A slight sourness often becomes more pronounced in well-aged examples, along with some sherry-like character, producing a "sweet-and-sour" profile.  The sourness should not grow to a notable acetic/vinegary character.  Hop flavor absent.  Restrained hop bitterness.  Low oxidation is appropriate as a point of complexity.  Diacetyl is perceived only in very minor quantities, if at all, as a complementary flavor.', 'Medium to medium-full body.  Low to moderate carbonation.  No astringency with a sweet and tart finish.', 'A malty, fruity, aged, somewhat sour Belgian-style brown ale.', 'Long aging and blending of young and aged beer may occur, adding smoothness and complexity and balancing any harsh, sour character.  A deeper malt character distinguishes these beers from Flanders red ales.  This style was designed to lay down so examples with a moderate aged character are considered superior to younger examples.  As in fruit lambics, Oud Bruin can be used as a base for fruit-flavored beers such as kriek (cherries) or frambozen (raspberries), though these should be entered in the classic-style fruit beer category.  The Oud Bruin is less acetic and maltier than a Flanders Red, and the fruity flavors are more malt-oriented.', 'A base of Pils malt with judicious amounts of dark cara malts and a tiny bit of black or roast malt.  Often includes maize.  Low alpha acid continental hops are typical (avoid high alpha or distinctive American hops).  Saccharomyces and Lactobacillus (and acetobacter) contribute to the fermentation and eventual flavor.  Lactobacillus reacts poorly to elevated levels of alcohol.  A sour mash or acidulated malt may also be used to develop the sour character without introducing Lactobacillus.  Water high in carbonates is typical of its home region and will buffer the acidity of darker malts and the lactic sourness.  Magnesium in the water accentuates the sourness.', 1.04000000000000004, 1.07400000000000007, 1.00800000000000001, 1.01200000000000001, 20, 25, 15, 22, 4, 8, 'Liefman''s Goudenband, Liefman''s Odnar, Liefman''s Oud Bruin, Ichtegem Old Brown, Riva Vondel');
INSERT INTO "BjcpStyle" VALUES ('beer', 17, 'Sour Ale', '17D', 'Straight (Unblended) Lambic', 'A decidedly sour/acidic aroma is often dominant in young examples, but may be more subdued with age as it blends with aromas described as barnyard, earthy, goaty, hay, horsey, and horse blanket.  A mild oak and/or citrus aroma is considered favorable.  An enteric, smoky, cigar-like, or cheesy aroma is unfavorable.  Older versions are commonly fruity with aromas of apples or even honey.  No hop aroma.  No diacetyl.', 'Pale yellow to deep golden in color.  Age tends to darken the beer.  Clarity is hazy to good.  Younger versions are often cloudy, while older ones are generally clear.  Head retention is generally poor.  Head color is white.', 'Young examples are often noticeably sour and/or lactic, but aging can bring this character more in balance with the malt, wheat and barnyard characteristics.  Fruity flavors are simpler in young lambics and more complex in the older examples, where they are reminiscent of apples or other light fruits, rhubarb, or honey.  Some oak or citrus flavor (often grapefruit) is occasionally noticeable.  An enteric, smoky or cigar-like character is undesirable.  Hop bitterness is low to none.  No hop flavor.  No diacetyl.', 'Light to medium-light body.  In spite of the low finishing gravity, the many mouth-filling flavors prevent the beer from tasting like water.  As a rule of thumb lambic dries with age, which makes dryness a reasonable indicator of age.  Has a medium to high tart, puckering quality without being sharply astringent.  Virtually to completely uncarbonated.', 'Complex, sour/acidic, pale, wheat-based ale fermented by a variety of Belgian microbiota.', 'Straight lambics are single-batch, unblended beers.  Since they are unblended, the straight lambic is often a true product of the "house character" of a brewery and will be more variable than a gueuze.  They are generally served young (6 months) and on tap as cheap, easy-drinking beers without any filling carbonation.  Younger versions tend to be one-dimensionally sour since a complex Brett character often takes upwards of a year to develop.  An enteric character is often indicative of a lambic that is too young.  A noticeable vinegary or cidery character is considered a fault by Belgian brewers.  Since the wild yeast and bacteria will ferment ALL sugars, they are bottled only when they have completely fermented.  Lambic is served uncarbonated, while gueuze is served effervescent.  IBUs are approximate since aged hops are used; Belgians use hops for anti-bacterial properties more than bittering in lambics.', 'Unmalted wheat (30-40%), Pilsner malt and aged (surannes) hops (3 years) are used.  The aged hops are used more for preservative effects than bitterness, and makes actual bitterness levels difficult to estimate.  Traditionally these beers are spontaneously fermented with naturally-occurring yeast and bacteria in predominately oaken barrels.  Home-brewed and craft-brewed versions are more typically made with pure cultures of yeast commonly including Saccharomyces, Brettanomyces, Pediococcus and Lactobacillus in an attempt to recreate the effects of the dominant microbiota of Brussels and the surrounding countryside of the Senne River valley.  Cultures taken from bottles are sometimes used but there is no simple way of knowing what organisms are still viable.', 1.04000000000000004, 1.05400000000000005, 1.00099999999999989, 1.01000000000000001, NULL, NULL, 3, 7, 5, 6.5, 'The only bottled version readily available is Cantillon Grand Cru Bruocsella of whatever single batch vintage the brewer deems worthy to bottle.  De Cam sometimes bottles their very old (5 years) lambic.  In and around Brussels there are specialty cafes that often have draught lambics from traditional brewers or blenders such as Boon, De Cam, Cantillon, Drie Fonteinen, Lindemans, Timmermans and Girardin.');
INSERT INTO "BjcpStyle" VALUES ('beer', 17, 'Sour Ale', '17E', 'Gueuze', 'A moderately sour/acidic aroma blends with aromas described as barnyard, earthy, goaty, hay, horsey, and horse blanket.  While some may be more dominantly sour/acidic, balance is the key and denotes a better gueuze.  Commonly fruity with aromas of citrus fruits (often grapefruit), apples or other light fruits, rhubarb, or honey.  A very mild oak aroma is considered favorable.  An enteric, smoky, cigar-like, or cheesy aroma is unfavorable.  No hop aroma.  No diacetyl.', 'Golden in color.  Clarity is excellent (unless the bottle was shaken).  A thick rocky, mousse-like, white head seems to last forever.  Always effervescent.', 'A moderately sour/acidic character is classically in balance with the malt, wheat and barnyard characteristics.  A low, complementary sweetness may be present but higher levels are uncharacteristic.  While some may be more dominantly sour, balance is the key and denotes a better gueuze.  A varied fruit flavor is common, and can have a honey-like character.  A mild vanilla and/or oak flavor is occasionally noticeable.  An enteric, smoky or cigar-like character is undesirable.  Hop bitterness is generally absent but a very low hop bitterness may occasionally be perceived.  No hop flavor.  No diacetyl.', 'Light to medium-light body.  In spite of the low finishing gravity, the many mouth-filling flavors prevent the beer from tasting like water.  Has a low to high tart, puckering quality without being sharply astringent.  Some versions have a low warming character.  Highly carbonated.', 'Complex, pleasantly sour/acidic, balanced, pale, wheat-based ale fermented by a variety of Belgian microbiota.', 'Gueuze is traditionally produced by mixing one, two, and three-year old lambic.  "Young" lambic contains fermentable sugars while old lambic has the characteristic "wild" taste of the Senne River valley.  A good gueuze is not the most pungent, but possesses a full and tantalizing bouquet, a sharp aroma, and a soft, velvety flavor.  Lambic is served uncarbonated, while gueuze is served effervescent.  IBUs are approximate since aged hops are used; Belgians use hops for anti-bacterial properties more than bittering in lambics.  Products marked "oude" or "ville" are considered most traditional.', 'Unmalted wheat (30-40%), Pilsner malt and aged (surannes) hops (3 years) are used.  The aged hops are used more for preservative effects than bitterness, and makes actual bitterness levels difficult to estimate.  Traditionally these beers are spontaneously fermented with naturally-occurring yeast and bacteria in predominately oaken barrels.  Home-brewed and craft-brewed versions are more typically made with pure cultures of yeast commonly including Saccharomyces, Brettanomyces, Pediococcus and Lactobacillus in an attempt to recreate the effects of the dominant microbiota of Brussels and the surrounding countryside of the Senne River valley.  Cultures taken from bottles are sometimes used but there is no simple way of knowing what organisms are still viable.', 1.04000000000000004, 1.06000000000000005, 1, 1.00600000000000001, NULL, NULL, 3, 7, 5, 8, 'Boon Oude Gueuze, Boon Oude Gueuze Mariage Parfait, De Cam Gueuze, De Cam/Drei Fonteinen Millennium Gueuze, Drie Fonteinen Oud Gueuze, Cantillon Gueuze, Hanssens Oude Gueuze, Lindemans Gueuze CuvÃ©e RenÃ©, Girardin Gueuze (Black Label), Mort Subite (Unfiltered) Gueuze, Oud Beersel Oude Gueuze');
INSERT INTO "BjcpStyle" VALUES ('beer', 17, 'Sour Ale', '17F', 'Fruit Lambic', 'The fruit which has been added to the beer should be the dominant aroma.  A low to moderately sour/acidic character blends with aromas described as barnyard, earthy, goaty, hay, horsey, and horse blanket (and thus should be recognizable as a lambic).  The fruit aroma commonly blends with the other aromas.  An enteric, smoky, cigar-like, or cheesy aroma is unfavorable.  No hop aroma.  No diacetyl.', 'The variety of fruit generally determines the color though lighter-colored fruit may have little effect on the color.  The color intensity may fade with age.  Clarity is often good, although some fruit will not drop bright.  A thick rocky, mousse-like head, sometimes a shade of fruit, is generally long-lasting.  Always effervescent.', 'The fruit added to the beer should be evident.  A low to moderate sour and more commonly (sometimes high) acidic character is present.  The classic barnyard characteristics may be low to high.  When young, the beer will present its full fruity taste.  As it ages, the lambic taste will become dominant at the expense of the fruit characterâ€“thus fruit lambics are not intended for long aging.  A low, complementary sweetness may be present, but higher levels are uncharacteristic.  A mild vanilla and/or oak flavor is occasionally noticeable.  An enteric, smoky or cigar-like character is undesirable.  Hop bitterness is generally absent.  No hop flavor.  No diacetyl.', 'Light to medium-light body.  In spite of the low finishing gravity, the many mouth-filling flavors prevent the beer from tasting like water.  Has a low to high tart, puckering quality without being sharply astringent.  Some versions have a low warming character.  Highly carbonated.', 'Complex, fruity, pleasantly sour/acidic, balanced, pale, wheat-based ale fermented by a variety of Belgian microbiota.  A lambic with fruit, not just a fruit beer.', 'Fruit-based lambics are often produced like gueuze by mixing one, two, and three-year old lambic.  "Young" lambic contains fermentable sugars while old lambic has the characteristic "wild" taste of the Senne River valley.  Fruit is commonly added halfway through aging and the yeast and bacteria will ferment all sugars from the fruit.  Fruit may also be added to unblended lambic.  The most traditional styles of fruit lambics include kriek (cherries), framboise (raspberries) and druivenlambik (muscat grapes). ENTRANT MUST SPECIFY THE TYPE OF FRUIT(S) USED IN MAKING THE LAMBIC.  Any overly sweet lambics (e.g., Lindemans or Belle Vue clones) would do better entered in the 16E Belgian Specialty category since this category does not describe beers with that character.  IBUs are approximate since aged hops are used; Belgians use hops for anti-bacterial properties more than bittering in lambics.', 'Unmalted wheat (30-40%), Pilsner malt and aged (surannes) hops (3 years) are used.  The aged hops are used more for preservative effects than bitterness, and makes actual bitterness levels difficult to estimate.  Traditional products use 10-30% fruit (25%, if cherry).  Fruits traditionally used include tart cherries (with pits), raspberries or Muscat grapes.  More recent examples include peaches, apricots or merlot grapes.  Tart or acidic fruit is traditionally used as its purpose is not to sweeten the beer but to add a new dimension.  Traditionally these beers are spontaneously fermented with naturally-occurring yeast and bacteria in predominately oaken barrels.  Home-brewed and craft-brewed versions are more typically made with pure cultures of yeast commonly including Saccharomyces, Brettanomyces, Pediococcus and Lactobacillus in an attempt to recreate the effects of the dominant microbiota of Brussels and the surrounding countryside of the Senne River valley.  Cultures taken from bottles are sometimes used but there is no simple way of knowing what organisms are still viable.', 1.04000000000000004, 1.06000000000000005, 1, 1.01000000000000001, NULL, NULL, 3, 7, 5, 7, 'Boon Framboise Marriage Parfait, Boon Kriek Mariage Parfait, Boon Oude Kriek, Cantillon Fou'' Foune (apricot), Cantillon Kriek, Cantillon Lou Pepe Kriek, Cantillon Lou Pepe Framboise, Cantillon Rose de Gambrinus, Cantillon St. Lamvinus (merlot grape), Cantillon Vigneronne (Muscat grape), De Cam Oude Kriek, Drie Fonteinen Kriek, Girardin Kriek, Hanssens Oude Kriek, Oud Beersel Kriek, Mort Subite Kriek');
INSERT INTO "BjcpStyle" VALUES ('beer', 18, 'Belgian Strong Ale', '18A', 'Belgian Blond Ale', 'Light earthy or spicy hop nose, along with a lightly sweet Pils malt character.  Shows a subtle yeast character that may include spicy phenolics, perfumy or honey-like alcohol, or yeasty, fruity esters (commonly orange-like or lemony).  Light sweetness that may have a slightly sugar-like character.  Subtle yet complex.', 'Light to deep gold color.  Generally very clear.  Large, dense, and creamy white to off-white head.  Good head retention with Belgian lace.', 'Smooth, light to moderate Pils malt sweetness initially, but finishes medium-dry to dry with some smooth alcohol becoming evident in the aftertaste.  Medium hop and alcohol bitterness to balance.  Light hop flavor, can be spicy or earthy.  Very soft yeast character (esters and alcohols, which are sometimes perfumy or orange/lemon-like).  Light spicy phenolics optional.  Some lightly caramelized sugar or honey-like sweetness on palate.', 'Medium-high to high carbonation, can give mouth-filling bubbly sensation.  Medium body.  Light to moderate alcohol warmth, but smooth.  Can be somewhat creamy.', 'A moderate-strength golden ale that has a subtle Belgian complexity, slightly sweet flavor, and dry finish.', 'Similar strength as a dubbel, similar character as a Belgian Strong Golden Ale or Tripel, although a bit sweeter and not as bitter.  Often has an almost lager-like character, which gives it a cleaner profile in comparison to the other styles. Belgians use the term "Blond," while the French spell it "Blonde."  Most commercial examples are in the 6.5 - 7% ABV range.  Many Trappist table beers (singles or Enkels) are called "Blond" but these are not representative of this style.', 'Belgian Pils malt, aromatic malts, sugar, Belgian yeast strains that produce complex alcohol, phenolics and perfumy esters, noble, Styrian Goldings or East Kent Goldings hops.  No spices are traditionally used, although the ingredients and fermentation by-products may give an impression of spicing (often reminiscent of oranges or lemons).', 1.06200000000000006, 1.07499999999999996, 1.00800000000000001, 1.01800000000000002, 15, 30, 4, 7, 6, 7.5, 'Leffe Blond, Affligem Blond, La Trappe (Koningshoeven) Blond, Grimbergen Blond, Val-Dieu Blond, Straffe Hendrik Blonde, Brugse Zot, Pater Lieven Blond Abbey Ale, Troubadour Blond Ale');
INSERT INTO "BjcpStyle" VALUES ('beer', 18, 'Belgian Strong Ale', '18B', 'Belgian Dubbel', 'Complex, rich malty sweetness; malt may have hints of chocolate, caramel and/or toast (but never roasted or burnt aromas).  Moderate fruity esters (usually including raisins and plums, sometimes also dried cherries).  Esters sometimes include banana or apple.  Spicy phenols and higher alcohols are common (may include light clove and spice, peppery, rose-like and/or perfumy notes).  Spicy qualities can be moderate to very low.  Alcohol, if present, is soft and never hot or solventy.  A small number of examples may include a low noble hop aroma, but hops are usually absent.  No diacetyl.', 'Dark amber to copper in color, with an attractive reddish depth of color.  Generally clear.  Large, dense, and long-lasting creamy off-white head.', 'Similar qualities as aroma.  Rich, complex medium to medium-full malty sweetness on the palate yet finishes moderately dry.  Complex malt, ester, alcohol and phenol interplay (raisiny flavors are common; dried fruit flavors are welcome; clove-like spiciness is optional).  Balance is always toward the malt.  Medium-low bitterness that doesn''t persist into the finish.  Low noble hop flavor is optional and not usually present.  No diacetyl.  Should not be as malty as a bock and should not have crystal malt-type sweetness.  No spices.', 'Medium-full body.  Medium-high carbonation, which can influence the perception of body.  Low alcohol warmth.  Smooth, never hot or solventy.', ': A deep reddish, moderately strong, malty, complex Belgian ale.', 'Most commercial examples are in the 6.5 - 7% ABV range. Traditionally bottle-conditioned ("refermented in the bottle").', 'Belgian yeast strains prone to production of higher alcohols, esters, and phenolics are commonly used.  Water can be soft to hard.  Impression of complex grain bill, although traditional versions are typically Belgian Pils malt with caramelized sugar syrup or other unrefined sugars providing much of the character.  Homebrewers may use Belgian Pils or pale base malt, Munich-type malts for maltiness, Special B for raisin flavors, CaraVienne or CaraMunich for dried fruit flavors, other specialty grains for character.  Dark caramelized sugar syrup or sugars for color and rum-raisin flavors.  Noble-type, English-type or Styrian Goldings hops commonly used.  No spices are traditionally used, although restrained use is allowable.', 1.06200000000000006, 1.07499999999999996, 1.00800000000000001, 1.01800000000000002, 15, 25, 10, 17, 6.29999999999999982, 7.59999999999999964, 'Westmalle Dubbel, St. Bernardus Pater 6, La Trappe Dubbel, Corsendonk Abbey Brown Ale, Grimbergen Double, Affligem Dubbel, Chimay Premiere (Red), Pater Lieven Bruin, Duinen Dubbel, St. Feuillien Brune, New Belgium Abbey Belgian Style Ale, Stoudts Abbey Double Ale, Russian River Benediction, Flying Fish Dubbel, Lost Abbey Lost and Found Abbey Ale, Allagash Double');
INSERT INTO "BjcpStyle" VALUES ('beer', 18, 'Belgian Strong Ale', '18C', 'Belgian Tripel', 'Complex with moderate to significant spiciness, moderate fruity esters and low alcohol and hop aromas.  Generous spicy, peppery, sometimes clove-like phenols.  Esters are often reminiscent of citrus fruits such as oranges, but may sometimes have a slight banana character.  A low yet distinctive spicy, floral, sometimes perfumy hop character is usually found.  Alcohols are soft, spicy and low in intensity.  No hot alcohol or solventy aromas.  The malt character is light.  No diacetyl.', 'Deep yellow to deep gold in color.  Good clarity.  Effervescent.  Long-lasting, creamy, rocky, white head resulting in characteristic "Belgian lace" on the glass as it fades.', 'Marriage of spicy, fruity and alcohol flavors supported by a soft malt character.  Low to moderate phenols are peppery in character.  Esters are reminiscent of citrus fruit such as orange or sometimes lemon.  A low to moderate spicy hop character is usually found.  Alcohols are soft, spicy, often a bit sweet and low in intensity.  Bitterness is typically medium to high from a combination of hop bitterness and yeast-produced phenolics.  Substantial carbonation and bitterness lends a dry finish with a moderately bitter aftertaste.  No diacetyl.', 'Medium-light to medium body, although lighter than the substantial gravity would suggest (thanks to sugar and high carbonation).  High alcohol content adds a pleasant creaminess but little to no obvious warming sensation.  No hot alcohol or solventy character.  Always effervescent.  Never astringent.', 'Strongly resembles a Strong Golden Ale but slightly darker and somewhat fuller-bodied.  Usually has a more rounded malt flavor but should not be sweet.', 'High in alcohol but does not taste strongly of alcohol.  The best examples are sneaky, not obvious.  High carbonation and attenuation helps to bring out the many flavors and to increase the perception of a dry finish.  Most Trappist versions have at least 30 IBUs and are very dry. Traditionally bottle-conditioned ("refermented in the bottle").', 'The light color and relatively light body for a beer of this strength are the result of using Pilsner malt and up to 20% white sugar.  Noble hops or Styrian Goldings are commonly used.  Belgian yeast strains are used â€“ those that produce fruity esters, spicy phenolics and higher alcohols Â– often aided by slightly warmer fermentation temperatures.  Spice additions are generally not traditional, and if used, should not be recognizable as such.  Fairly soft water.', 1.07499999999999996, 1.08499999999999996, 1.00800000000000001, 1.01400000000000001, 20, 40, 4.5, 7, 7.5, 9.5, 'Westmalle Tripel, La Rulles Tripel, St. Bernardus Tripel, Chimay Cinq Cents (White), Watou Tripel, Val-Dieu Triple, Affligem Tripel, Grimbergen Tripel, La Trappe Tripel, Witkap Pater Tripel, Corsendonk Abbey Pale Ale, St. Feuillien Tripel, Bink Tripel, Tripel Karmeliet, New Belgium Trippel, Unibroue La Fin du Monde, Dragonmead Final Absolution, Allagash Tripel Reserve, Victory Golden Monkey');
INSERT INTO "BjcpStyle" VALUES ('beer', 18, 'Belgian Strong Ale', '18D', 'Belgian Golden Strong Ale', 'Complex with significant fruity esters, moderate spiciness and low to moderate alcohol and hop aromas.  Esters are reminiscent of lighter fruits such as pears, oranges or apples.  Moderate spicy, peppery phenols.  A low to moderate yet distinctive perfumy, floral hop character is often present.  Alcohols are soft, spicy, perfumy and low-to-moderate in intensity.  No hot alcohol or solventy aromas.  The malt character is light.  No diacetyl.', 'Yellow to medium gold in color.  Good clarity.  Effervescent.  Massive, long-lasting, rocky, often beady, white head resulting in characteristic "Belgian lace" on the glass as it fades.', 'Marriage of fruity, spicy and alcohol flavors supported by a soft malt character.  Esters are reminiscent of pears, oranges or apples.  Low to moderate phenols are peppery in character.  A low to moderate spicy hop character is often present.  Alcohols are soft, spicy, often a bit sweet and are low-to-moderate in intensity.  Bitterness is typically medium to high from a combination of hop bitterness and yeast-produced phenolics.  Substantial carbonation and bitterness leads to a dry finish with a low to moderately bitter aftertaste.  No diacetyl.', 'Very highly carbonated. Light to medium body, although lighter than the substantial gravity would suggest (thanks to sugar and high carbonation).  Smooth but noticeable alcohol warmth.  No hot alcohol or solventy character.  Always effervescent.  Never astringent.', 'A golden, complex, effervescent, strong Belgian-style ale.', 'Strongly resembles a Tripel, but may be even paler, lighter-bodied and even crisper and drier.  The drier finish and lighter body also serves to make the assertive hopping and spiciness more prominent.  References to the devil are included in the names of many commercial examples of this style, referring to their potent alcoholic strength and as a tribute to the original example (Duvel).  The best examples are complex and delicate.  High carbonation helps to bring out the many flavors and to increase the perception of a dry finish. Traditionally bottle-conditioned ("refermented in the bottle").', 'The light color and relatively light body for a beer of this strength are the result of using Pilsner malt and up to 20% white sugar.  Noble hops or Styrian Goldings are commonly used.  Belgian yeast strains are used â€“ those that produce fruity esters, spicy phenolics and higher alcohols â€“ often aided by slightly warmer fermentation temperatures.  Fairly soft water.', 1.07000000000000006, 1.09499999999999997, 1.00499999999999989, 1.01600000000000001, 22, 35, 3, 6, 7.5, 10.5, 'Duvel, Russian River Damnation, Hapkin, Lucifer, Brigand, Judas, Delirium Tremens, Dulle Teve, Piraat, Great Divide Hades, Avery Salvation, North Coast Pranqster, Unibroue Eau Benite, AleSmith Horny Devil');
INSERT INTO "BjcpStyle" VALUES ('beer', 18, 'Belgian Strong Ale', '18E', 'Belgian Dark Strong Ale', 'Complex, with a rich malty sweetness, significant esters and alcohol, and an optional light to moderate spiciness.  The malt is rich and strong, and can have a Munich-type quality often with a caramel, toast and/or bready aroma.  The fruity esters are strong to moderately low, and can contain raisin, plum, dried cherry, fig or prune notes.  Spicy phenols may be present, but usually have a peppery quality not clove-like.  Alcohols are soft, spicy, perfumy and/or rose-like, and are low to moderate in intensity.  Hops are not usually present (but a very low noble hop aroma is acceptable).  No diacetyl.  No dark/roast malt aroma.  No hot alcohols or solventy aromas.  No recognizable spice additions.', 'Deep amber to deep coppery-brown in color ("dark" in this context implies "more deeply colored than golden").  Huge, dense, moussy, persistent cream- to light tan-colored head.  Can be clear to somewhat hazy.', 'Similar to aroma (same malt, ester, phenol, alcohol, hop and spice comments apply to flavor as well).  Moderately malty or sweet on palate.  Finish is variable depending on interpretation (authentic Trappist versions are moderately dry to dry, Abbey versions can be medium-dry to sweet).  Low bitterness for a beer of this strength; alcohol provides some of the balance to the malt.  Sweeter and more full-bodied beers will have a higher bitterness level to balance.  Almost all versions are malty in the balance, although a few are lightly bitter.  The complex and varied flavors should blend smoothly and harmoniously.', 'High carbonation but no carbonic acid "bite."  Smooth but noticeable alcohol warmth.  Body can be variable depending on interpretation (authentic Trappist versions tend to be medium-light to medium, while Abbey-style beers can be quite full and creamy).', 'A dark, very rich, complex, very strong Belgian ale.  Complex, rich, smooth and dangerous.', 'Authentic Trappist versions tend to be drier (Belgians would say "more digestible") than Abbey versions, which can be rather sweet and full-bodied.  Higher bitterness is allowable in Abbey-style beers with a higher FG.  Barleywine-type beers (e.g., Scaldis/Bush, La Trappe Quadrupel, Weyerbacher QUAD) and Spiced/Christmas-type beers (e.g., N''ice Chouffe, Affligem NÃ¶el) should be entered in the Belgian Specialty Ale category (16E), not this category. Traditionally bottle-conditioned ("refermented in the bottle").', 'Belgian yeast strains prone to production of higher alcohols, esters, and sometimes phenolics are commonly used.  Water can be soft to hard.  Impression of a complex grain bill, although many traditional versions are quite simple, with caramelized sugar syrup or unrefined sugars and yeast providing much of the complexity.  Homebrewers may use Belgian Pils or pale base malt, Munich-type malts for maltiness, other Belgian specialty grains for character.  Caramelized sugar syrup or unrefined sugars lightens body and adds color and flavor (particularly if dark sugars are used).  Noble-type, English-type or Styrian Goldings hops commonly used.  Spices generally not used; if used, keep subtle and in the background.  Avoid US/UK crystal type malts (these provide the wrong type of sweetness).', 1.07499999999999996, 1.1100000000000001, 1.01000000000000001, 1.02400000000000002, 20, 30, 12, 22, 8, 11, 'Westvleteren 12 (yellow cap), Rochefort 10 (blue cap), St. Bernardus Abt 12, Gouden Carolus Grand Cru of the Emperor, Achel Extra Brune, Rochefort 8 (green cap), Southampton Abbot 12, Chimay Grande Reserve (Blue), Brasserie des Rocs Grand Cru, Gulden Draak, Kasteelbier BiÃ¨re du Chateau Donker, Lost Abbey Judgment Day, Russian River Salvation');
INSERT INTO "BjcpStyle" VALUES ('beer', 1, 'Light Lager', '1B', 'Standard American Lager', 'Little to no malt aroma, although it can be grainy, sweet or corn-like if present.  Hop aroma may range from none to a light, spicy or floral hop presence.  Low levels of yeast character (green apples, DMS, or fruitiness) are optional but acceptable.  No diacetyl.', 'Very pale straw to medium yellow color.  White, frothy head seldom persists.  Very clear.', 'Crisp and dry flavor with some low levels of grainy or corn-like sweetness.  Hop flavor ranges from none to low levels.  Hop bitterness at low to medium-low level.  Balance may vary from slightly malty to slightly bitter, but is relatively close to even.  High levels of carbonation may provide a slight acidity or dry "sting."  No diacetyl.  No fruitiness.', 'Light body from use of a high percentage of adjuncts such as rice or corn.  Very highly carbonated with slight carbonic bite on the tongue.', 'Very refreshing and thirst quenching.', 'Strong flavors are a fault.  An international style including the standard mass-market lager from most countries.', 'Two- or six-row barley with high percentage (up to 40%) of rice or corn as adjuncts.', 1.04000000000000004, 1.05000000000000004, 1.004, 1.01000000000000001, 8, 15, 2, 4, 4.20000000000000018, 5.29999999999999982, 'Pabst Blue Ribbon, Miller High Life, Budweiser, Baltika #3 Classic, Kirin Lager, Grain Belt Premium Lager, Molson Golden, Labatt Blue, Coors Original, Foster''s Lager');
INSERT INTO "BjcpStyle" VALUES ('beer', 19, 'Strong Ale', '19A', 'Old Ale', 'Malty-sweet with fruity esters, often with a complex blend of dried-fruit, vinous, caramelly, molasses, nutty, toffee, treacle, and/or other specialty malt aromas.  Some alcohol and oxidative notes are acceptable, akin to those found in Sherry or Port. Hop aromas not usually present due to extended aging.', 'Light amber to very dark reddish-brown color (most are fairly dark).  Age and oxidation may darken the beer further.  May be almost opaque (if not, should be clear).  Moderate to low cream- to light tan-colored head; may be adversely affected by alcohol and age.', 'Medium to high malt character with a luscious malt complexity, often with nutty, caramelly and/or molasses-like flavors.  Light chocolate or roasted malt flavors are optional, but should never be prominent.  Balance is often malty-sweet, but may be well hopped (the impression of bitterness often depends on amount of aging).  Moderate to high fruity esters are common, and may take on a dried-fruit or vinous character.  The finish may vary from dry to somewhat sweet.  Extended aging may contribute oxidative flavors similar to a fine old Sherry, Port or Madeira. Alcoholic strength should be evident, though not overwhelming.  Diacetyl low to none.  Some wood-aged or blended versions may have a lactic or Brettanomyces character; but this is optional and should not be too strong (enter as a specialty beer if it is).', 'Medium to full, chewy body, although older examples may be lower in body due to continued attenuation during conditioning.  Alcohol warmth is often evident and always welcome.  Low to moderate carbonation, depending on age and conditioning.', 'An ale of significant alcoholic strength, bigger than strong bitters and brown porters, though usually not as strong or rich as barleywine. Usually tilted toward a sweeter, maltier balance. "It should be a warming beer of the type that is best drunk in half pints by a warm fire on a cold winter''s night" Â– Michael Jackson.', 'Strength and character varies widely.  Fits in the style space between normal gravity beers (strong bitters, brown porters) and barleywines.  Can include winter warmers, strong dark milds, strong (and perhaps darker) bitters, blended strong beers (stock ale blended with a mild or bitter), and lower gravity versions of English barleywines.  Many English examples, particularly winter warmers, are lower than 6% ABV.', 'Generous quantities of well-modified pale malt (generally English in origin, though not necessarily so), along with judicious quantities of caramel malts and other specialty character malts. Some darker examples suggest that dark malts (e.g., chocolate, black malt) may be appropriate, though sparingly so as to avoid an overly roasted character. Adjuncts (such as molasses, treacle, invert sugar or dark sugar) are often used, as are starchy adjuncts (maize, flaked barley, wheat) and malt extracts. Hop variety is not as important, as the relative balance and aging process negate much of the varietal character.  British ale yeast that has low attenuation, but can handle higher alcohol levels, is traditional.', 1.06000000000000005, 1.09000000000000008, 1.0149999999999999, 1.02200000000000002, 30, 60, 10, 22, 6, 9, 'Gale''s Prize Old Ale, Burton Bridge Olde Expensive, Marston Owd Roger, Greene King Olde Suffolk Ale , J.W. Lees Moonraker, Harviestoun Old Engine Oil, Fuller''s Vintage Ale, Harvey''s Elizabethan Ale, Theakston Old Peculier (peculiar at OG 1.057), Young''s Winter Warmer, Sarah Hughes Dark Ruby Mild, Samuel Smith''s Winter Welcome, Fuller''s 1845, Fuller''s Old Winter Ale, Great Divide Hibernation Ale, Founders Curmudgeon, Cooperstown Pride of Milford Special Ale, Coniston Old Man Ale, Avery Old Jubilation');
INSERT INTO "BjcpStyle" VALUES ('beer', 19, 'Strong Ale', '19B', 'English Barleywine', 'Very rich and strongly malty, often with a caramel-like aroma.  May have moderate to strong fruitiness, often with a dried-fruit character.  English hop aroma may range from mild to assertive.  Alcohol aromatics may be low to moderate, but never harsh, hot or solventy.  The intensity of these aromatics often subsides with age.  The aroma may have a rich character including bready, toasty, toffee, molasses, and/or treacle notes.  Aged versions may have a sherry-like quality, possibly vinous or port-like aromatics, and generally more muted malt aromas.  Low to no diacetyl.', 'Color may range from rich gold to very dark amber or even dark brown. Often has ruby highlights, but should not be opaque. Low to moderate off-white head; may have low head retention.  May be cloudy with chill haze at cooler temperatures, but generally clears to good to brilliant clarity as it warms.  The color may appear to have great depth, as if viewed through a thick glass lens.  High alcohol and viscosity may be visible in "legs" when beer is swirled in a glass.', 'Strong, intense, complex, multi-layered malt flavors ranging from bready and biscuity through nutty, deep toast, dark caramel, toffee, and/or molasses.  Moderate to high malty sweetness on the palate, although the finish may be moderately sweet to moderately dry (depending on aging). Some oxidative or vinous flavors may be present, and often complex alcohol flavors should be evident.  Alcohol flavors shouldn''t be harsh, hot or solventy.  Moderate to fairly high fruitiness, often with a dried-fruit character.  Hop bitterness may range from just enough for balance to a firm presence; balance therefore ranges from malty to somewhat bitter.  Low to moderately high hop flavor (usually UK varieties).  Low to no diacetyl.', 'Full-bodied and chewy, with a velvety, luscious texture (although the body may decline with long conditioning).  A smooth warmth from aged alcohol should be present, and should not be hot or harsh.  Carbonation may be low to moderate, depending on age and conditioning.', 'The richest and strongest of the English Ales.  A showcase of malty richness and complex, intense flavors.  The character of these ales can change significantly over time; both young and old versions should be appreciated for what they are.  The malt profile can vary widely; not all examples will have all possible flavors or aromas.', 'Although often a hoppy beer, the English Barleywine places less emphasis on hop character than the American Barleywine and features English hops.  English versions can be darker, maltier, fruitier, and feature richer specialty malt flavors than American Barleywines.', 'Well-modified pale malt should form the backbone of the grist, with judicious amounts of caramel malts. Dark malts should be used with great restraint, if at all, as most of the color arises from a lengthy boil.  English hops such as Northdown, Target, East Kent Goldings and Fuggles.  Characterful English yeast.', 1.08000000000000007, 1.12000000000000011, 1.01800000000000002, 1.03000000000000003, 35, 70, 8, 22, 8, 12, 'Thomas Hardy''s Ale, Burton Bridge Thomas Sykes Old Ale, J.W. Lee''s Vintage Harvest Ale, Robinson''s Old Tom, Fuller''s Golden Pride, AleSmith Old Numbskull, Young''s Old Nick (unusual in its 7.2% ABV), Whitbread Gold Label, Old Dominion Millenium, North Coast Old Stock Ale (when aged), Weyerbacher Blithering Idiot');
INSERT INTO "BjcpStyle" VALUES ('beer', 19, 'Strong Ale', '19C', 'American Barleywine', 'Very rich and intense maltiness.  Hop character moderate to assertive and often showcases citrusy or resiny American varieties (although other varieties, such as floral, earthy or spicy English varieties or a blend of varieties, may be used).  Low to moderately strong fruity esters and alcohol aromatics.  Malt character may be sweet, caramelly, bready, or fairly neutral.  However, the intensity of aromatics often subsides with age.  No diacetyl.', 'Color may range from light amber to medium copper; may rarely be as dark as light brown. Often has ruby highlights. Moderately-low to large off-white to light tan head; may have low head retention.  May be cloudy with chill haze at cooler temperatures, but generally clears to good to brilliant clarity as it warms.  The color may appear to have great depth, as if viewed through a thick glass lens.  High alcohol and viscosity may be visible in "legs" when beer is swirled in a glass.', 'Strong, intense malt flavor with noticeable bitterness.  Moderately low to moderately high malty sweetness on the palate, although the finish may be somewhat sweet to quite dry (depending on aging). Hop bitterness may range from moderately strong to aggressive.  While strongly malty, the balance should always seem bitter.  Moderate to high hop flavor (any variety).  Low to moderate fruity esters.  Noticeable alcohol presence, but sharp or solventy alcohol flavors are undesirable.  Flavors will smooth out and decline over time, but any oxidized character should be muted (and generally be masked by the hop character).  May have some bready or caramelly malt flavors, but these should not be high.  Roasted or burnt malt flavors are inappropriate.  No diacetyl.', 'Full-bodied and chewy, with a velvety, luscious texture (although the body may decline with long conditioning).  Alcohol warmth should be present, but not be excessively hot.  Should not be syrupy and under-attenuated.  Carbonation may be low to moderate, depending on age and conditioning.', 'A well-hopped American interpretation of the richest and strongest of the English ales.  The hop character should be evident throughout, but does not have to be unbalanced.  The alcohol strength and hop bitterness often combine to leave a very long finish.', 'The American version of the Barleywine tends to have a greater emphasis on hop bitterness, flavor and aroma than the English Barleywine, and often features American hop varieties.  Differs from an Imperial IPA in that the hops are not extreme, the malt is more forward, and the body is richer and more characterful.', 'Well-modified pale malt should form the backbone of the grist.  Some specialty or character malts may be used.  Dark malts should be used with great restraint, if at all, as most of the color arises from a lengthy boil.   Citrusy American hops are common, although any varieties can be used in quantity.  Generally uses an attenuative American yeast.', 1.08000000000000007, 1.12000000000000011, 1.01600000000000001, 1.03000000000000003, 50, 120, 10, 19, 8, 12, 'Sierra Nevada Bigfoot, Great Divide Old Ruffian, Victory Old Horizontal, Rogue Old Crustacean, Avery Hog Heaven Barleywine, Bell''s Third Coast Old Ale, Anchor Old Foghorn, Three Floyds Behemoth, Stone Old Guardian, Bridgeport Old Knucklehead, Hair of the Dog Doggie Claws, Lagunitas Olde GnarleyWine, Smuttynose Barleywine, Flying Dog Horn Dog');
INSERT INTO "BjcpStyle" VALUES ('beer', 1, 'Light Lager', '1A', 'Lite American Lager', 'Little to no malt aroma, although it can be grainy, sweet or corn-like if present.  Hop aroma may range from none to a light, spicy or floral hop presence.  Low levels of yeast character (green apples, DMS, or fruitiness) are optional but acceptable.  No diacetyl.', 'Very pale straw to pale yellow color.  White, frothy head seldom persists.  Very clear.', 'Crisp and dry flavor with some low levels of grainy or corn-like sweetness.  Hop flavor ranges from none to low levels.  Hop bitterness at low level.  Balance may vary from slightly malty to slightly bitter, but is relatively close to even.  High levels of carbonation may provide a slight acidity or dry "sting."  No diacetyl.  No fruitiness.', 'Very light body from use of a high percentage of adjuncts such as rice or corn.  Very highly carbonated with slight carbonic bite on the tongue.  May seem watery.', 'Very refreshing and thirst quenching.', 'A lower gravity and lower calorie beer than standard international lagers.  Strong flavors are a fault. Designed to appeal to the broadest range of the general public as possible.', 'Two- or six-row barley with high percentage (up to 40%) of rice or corn as adjuncts.', 1.02800000000000002, 1.04000000000000004, 0.997999999999999998, 1.00800000000000001, 8, 12, 2, 3, 2.79999999999999982, 4.20000000000000018, 'Bitburger Light, Sam Adams Light, Heineken Premium Light, Miller Lite, Bud Light, Coors Light, Baltika #1 Light, Old Milwaukee Light, Amstel Light');
INSERT INTO "BjcpStyle" VALUES ('cider', 28, 'Specialty Cider and Perry', '28C', 'Applewine', 'Comparable to a Common Cider. Cider character must be distinctive. Very dry to slightly medium.', 'Clear to brilliant, pale to medium-gold. Cloudiness or hazes are inappropriate. Dark colors are not expected unless strongly tannic varieties of fruit were used.', 'Comparable to a Common Cider. Cider character must be distinctive. Very dry to slightly medium.', 'Lighter than other ciders, because higher alcohol is derived from addition of sugar rather than juice. Carbonation may range from still to champagne-like.', 'Like a dry white wine, balanced, and with low astringency and bitterness.', 'Entrants MUST specify carbonation level (still, petillant, or sparkling). Entrants MUST specify sweetness (dry or medium).', '', 1.07000000000000006, 1.10000000000000009, 0.994999999999999996, 1.01000000000000001, NULL, NULL, NULL, NULL, 9, 12, '[US] AEppelTreow Summer''s End (WI), Wandering Aengus Pommeau (OR), Uncle John''s Fruit House Winery Fruit House Apple (MI), Irvine''s Vintage Ciders (WA)');
INSERT INTO "BjcpStyle" VALUES ('beer', 1, 'Light Lager', '1C', 'Premium American Lager', 'Low to medium-low malt aroma, which can be grainy, sweet or corn-like.  Hop aroma may range from very low to a medium-low, spicy or floral hop presence.  Low levels of yeast character (green apples, DMS, or fruitiness) are optional but acceptable.  No diacetyl.', 'Pale straw to gold color.  White, frothy head may not be long lasting.  Very clear.', 'Crisp and dry flavor with some low levels of grainy or malty sweetness.  Hop flavor ranges from none to low levels.  Hop bitterness at low to medium level.  Balance may vary from slightly malty to slightly bitter, but is relatively close to even.  High levels of carbonation may provide a slight acidity or dry "sting."  No diacetyl.  No fruitiness.', 'Medium-light body from use of adjuncts such as rice or corn.  Highly carbonated with slight carbonic bite on the tongue.', 'Refreshing and thirst quenching, although generally more filling than standard/lite versions.', 'Premium beers tend to have fewer adjuncts than standard/lite lagers, and can be all-malt. Strong flavors are a fault, but premium lagers have more flavor than standard/lite lagers.  A broad category of international mass-market lagers ranging from up-scale American lagers to the typical "import" or "green bottle" international beers found in America.', 'Two- or six-row barley with up to 25% rice or corn as adjuncts.', 1.04600000000000004, 1.05600000000000005, 1.00800000000000001, 1.01200000000000001, 15, 25, 2, 6, 4.59999999999999964, 6, 'Full Sail Session Premium Lager, Miller Genuine Draft, Corona Extra, Michelob, Coors Extra Gold, Birra Moretti, Heineken, Beck''s, Stella Artois, Red Stripe, Singha');
INSERT INTO "BjcpStyle" VALUES ('beer', 1, 'Light Lager', '1D', 'Munich Helles', 'Pleasantly grainy-sweet, clean Pils malt aroma dominates. Low to moderately-low spicy noble hop aroma, and a low background note of DMS (from Pils malt).  No esters or diacetyl.', 'Medium yellow to pale gold, clear, with a creamy white head.', 'Slightly sweet, malty profile. Grain and Pils malt flavors dominate, with a low to medium-low hop bitterness that supports the malty palate. Low to moderately-low spicy noble hop flavor.  Finish and aftertaste remain malty.  Clean, no fruity esters, no diacetyl.', 'Medium body, medium carbonation, smooth maltiness with no trace of astringency.', 'Malty but fully attenuated Pils malt showcase.', 'Unlike Pilsner but like its cousin, Munich Dunkel, Helles is a malt-accentuated beer that is not overly sweet, but rather focuses on malt flavor with underlying hop bitterness in a supporting role.', 'Moderate carbonate water, Pilsner malt, German noble hop varieties.', 1.04499999999999993, 1.05099999999999993, 1.00800000000000001, 1.01200000000000001, 16, 22, 3, 5, 4.70000000000000018, 5.40000000000000036, 'Weihenstephaner Original, Hacker-Pschorr MÃ¼nchner Gold, BÃ¼rgerbrÃ¤u Wolznacher Hell NaturtrÃ¼b, Mahr''s Hell, Paulaner Premium Lager, Spaten Premium Lager, Stoudt''s Gold Lager');
INSERT INTO "BjcpStyle" VALUES ('beer', 1, 'Light Lager', '1E', 'Dortmunder Export', 'Low to medium noble (German or Czech) hop aroma.  Moderate Pils malt aroma; can be grainy to somewhat sweet. May have an initial sulfury aroma (from water and/or yeast) and a low background note of DMS (from Pils malt).  No diacetyl.', 'Light gold to deep gold, clear with a persistent white head.', 'Neither Pils malt nor noble hops dominate, but both are in good balance with a touch of malty sweetness, providing a smooth yet crisply refreshing beer. Balance continues through the finish and the hop bitterness lingers in aftertaste (although some examples may finish slightly sweet).  Clean, no fruity esters, no diacetyl.  Some mineral character might be noted from the water, although it usually does not come across as an overt minerally flavor.', 'Medium body, medium carbonation.', 'Balance and smoothness are the hallmarks of this style.  It has the malt profile of a Helles, the hop character of a Pils, and is slightly stronger than both.', 'Brewed to a slightly higher starting gravity than other light lagers, providing a firm malty body and underlying maltiness to complement the sulfate-accentuated hop bitterness.  The term "Export" is a beer strength category under German beer tax law, and is not strictly synonymous with the "Dortmunder" style.  Beer from other cities or regions can be brewed to Export strength, and labeled as such.', 'Minerally water with high levels of sulfates, carbonates and chlorides, German or Czech noble hops, Pilsner malt, German lager yeast.', 1.04800000000000004, 1.05600000000000005, 1.01000000000000001, 1.0149999999999999, 23, 30, 4, 6, 4.79999999999999982, 6, 'DAB Export, Dortmunder Union Export, Dortmunder Kronen, Ayinger Jahrhundert, Great Lakes Dortmunder Gold, Barrel House Duveneck''s Dortmunder, Bell''s Lager, Dominion Lager, Gordon Biersch Golden Export, Flensburger Gold');
INSERT INTO "BjcpStyle" VALUES ('beer', 22, 'Smoke-Flavored/Wood-Aged Beer', '22A', 'Classic Rauchbier', 'Blend of smoke and malt, with a varying balance and intensity.  The beechwood smoke character can range from subtle to fairly strong, and can seem smoky, bacon-like, woody, or rarely almost greasy.  The malt character can be low to moderate, and be somewhat sweet, toasty, or malty.  The malt and smoke components are often inversely proportional (i.e., when smoke increases, malt decreases, and vice versa).  Hop aroma may be very low to none.  Clean, lager character with no fruity esters, diacetyl or DMS.', 'This should be a very clear beer, with a large, creamy, rich, tan- to cream-colored head.  Medium amber/light copper to dark brown color.', 'Generally follows the aroma profile, with a blend of smoke and malt in varying balance and intensity, yet always complementary.  MÃ¤rzen-like qualities should be noticeable, particularly a malty, toasty richness, but the beechwood smoke flavor can be low to high.  The palate can be somewhat malty and sweet, yet the finish can reflect both malt and smoke.  Moderate, balanced, hop bitterness, with a medium-dry to dry finish (the smoke character enhances the dryness of the finish).  Noble hop flavor moderate to none.  Clean lager character with no fruity esters, diacetyl or DMS.  Harsh, bitter, burnt, charred, rubbery, sulfury or phenolic smoky characteristics are inappropriate.', 'Medium body.  Medium to medium-high carbonation.  Smooth lager character.  Significant astringent, phenolic harshness is inappropriate.', 'MÃ¤rzen/Oktoberfest-style (see 3B) beer with a sweet, smoky aroma and flavor and a somewhat darker color.', 'The intensity of smoke character can vary widely; not all examples are highly smoked.  Allow for variation in the style when judging.  Other examples of smoked beers are available in Germany, such as the Bocks, Hefe-Weizen, Dunkel, Schwarz, and Helles-like beers, including examples such as Spezial Lager. Brewers entering these styles should use Other Smoked Beer (22B) as the entry category.', 'German Rauchmalz (beechwood-smoked Vienna-type malt) typically makes up 20-100% of the grain bill, with the remainder being German malts typically used in a MÃ¤rzen.  Some breweries adjust the color slightly with a bit of roasted malt.  German lager yeast.  German or Czech hops.', 1.05000000000000004, 1.05699999999999994, 1.01200000000000001, 1.01600000000000001, 20, 30, 12, 22, 4.79999999999999982, 6, 'Schlenkerla Rauchbier MÃ¤rzen, Kaiserdom Rauchbier, Eisenbahn Rauchbier, Victory Scarlet Fire Rauchbier, Spezial Rauchbier MÃ¤rzen, Saranac Rauchbier');
INSERT INTO "BjcpStyle" VALUES ('cider', 27, 'Standard Cider and Perry', '27A', 'Common Cider ', 'Sweet or low-alcohol ciders may have apple aroma and flavor. Dry ciders will be more wine-like with some esters. Sugar and acidity should combine to give a refreshing character, neither cloying nor too austere. Medium to high acidity. ', 'Clear to brilliant, medium to deep gold color.', 'Sweet or low-alcohol ciders may have apple aroma and flavor. Dry ciders will be more wine-like with some esters. Sugar and acidity should combine to give a refreshing character, neither cloying nor too austere. Medium to high acidity. ', 'Medium body. Some tannin should be present for slight to moderate astringency, but little bitterness.', 'Variable, but should be a medium, refreshing drink. Sweet ciders must not be cloying. Dry ciders must not be too austere. An ideal cider serves well as a "session" drink, and suitably accompanies a wide variety of food.', 'Entrants MUST specify carbonation level (still, petillant, or sparkling). Entrants MUST specify sweetness (dry, medium, sweet).', '', 1.04499999999999993, 1.06499999999999995, 1, 1.02000000000000002, NULL, NULL, NULL, NULL, 5, 8, '[US] Red Barn Cider Jonagold Semi-Dry and Sweetie Pie (WA), AEppelTreow Barn Swallow Draft Cider (WI), Wandering Aengus Heirloom Blend Cider (OR), Uncle John''s Fruit House Winery Apple Hard Cider (MI), Bellwether Spyglass (NY), West County Pippin (MA), White Winter Hard Apple Cider (WI), Harpoon Cider (MA)');
INSERT INTO "BjcpStyle" VALUES ('cider', 27, 'Standard Cider and Perry', '27B', 'English Cider ', 'No overt apple character, but various flavors and esters that suggest apples. May have "smoky (bacon)" character from a combination of apple varieties and MLF. Some "Farmyard nose" may be present but must not dominate; mousiness is a serious fault. The common slight farmyard nose of an English West Country cider is the result of lactic acid bacteria, not a Brettanomyces contamination.', 'Slightly cloudy to brilliant. Medium to deep gold color.', 'No overt apple character, but various flavors and esters that suggest apples. May have "smoky (bacon)" character from a combination of apple varieties and MLF. Some "Farmyard nose" may be present but must not dominate; mousiness is a serious fault. The common slight farmyard nose of an English West Country cider is the result of lactic acid bacteria, not a Brettanomyces contamination.', 'Full. Moderate to high tannin apparent as astringency and some bitterness.  Carbonation still to moderate, never high or gushing.', 'Generally dry, full-bodied, austere.', 'Entrants MUST specify carbonation level (still or petillant). Entrants MUST specify sweetness (dry to medium). Entrants MAY specify variety of apple for a single varietal cider; if specified, varietal character will be expected.', '', 1.05000000000000004, 1.07499999999999996, 0.994999999999999996, 1.01000000000000001, NULL, NULL, NULL, NULL, 6, 9, '[US] Westcott Bay Traditional Very Dry, Traditional Dry and Traditional Medium Sweet (WA), Farnum Hill Extra-Dry, Dry, and Farmhouse (NH), Wandering Aengus Dry Cider (OR), Red Barn Cider Burro Loco (WA), Bellwether Heritage (NY); [UK] Oliver''s Herefordshire Dry Cider, various from Hecks, Dunkerton, Burrow Hill, Gwatkin Yarlington Mill, Aspall Dry Cider');
INSERT INTO "BjcpStyle" VALUES ('cider', 27, 'Standard Cider and Perry', '27C', 'French Cider', 'Fruity character/aroma. This may come from slow or arrested fermentation (in the French technique of dÃ©fÃ©cation) or approximated by back sweetening with juice. Tends to a rich fullness.', 'Clear to brilliant, medium to deep gold color.', 'Fruity character/aroma. This may come from slow or arrested fermentation (in the French technique of dÃ©fÃ©cation) or approximated by back sweetening with juice. Tends to a rich fullness.', 'Medium to full, mouth filling.  Moderate tannin apparent mainly as astringency. Carbonation moderate to champagne-like, but at higher levels it must not gush or foam.', 'Medium to sweet, full-bodied, rich.', 'Entrants MUST specify carbonation level (petillant or full). Entrants MUST specify sweetness (medium, sweet). Entrants MAY specify variety of apple for a single varietal cider; if specified, varietal character will be expected.', '', 1.05000000000000004, 1.06499999999999995, 1.01000000000000001, 1.02000000000000002, NULL, NULL, NULL, NULL, 3, 6, '[US] West County Reine de Pomme (MA), Rhyne Cider (CA); [France] Eric Bordelet (various), Etienne Dupont, Etienne Dupont Organic, Bellot');
INSERT INTO "BjcpStyle" VALUES ('cider', 27, 'Standard Cider and Perry', '27D', 'Common Perry', 'There is a pear character, but not obviously fruity. It tends toward that of a young white wine. No bitterness.', 'Slightly cloudy to clear. Generally quite pale.', 'There is a pear character, but not obviously fruity. It tends toward that of a young white wine. No bitterness.', ':  Relatively full, low to moderate tannin apparent as astringency.', 'Mild. Medium to medium-sweet. Still to lightly sparkling. Only very slight acetification is acceptable. Mousiness, ropy/oily characters are serious faults.', 'Entrants MUST specify carbonation level (still, petillant, or sparkling). Entrants MUST specify sweetness (medium or sweet).', '', 1.05000000000000004, 1.06000000000000005, 1, 1.02000000000000002, NULL, NULL, NULL, NULL, 5, 7.20000000000000018, '[US] White Winter Hard Pear Cider (WI), AEppelTreow Perry (WI), Blossomwood Laughing Pig Perry (CO), Uncle John''s Fruit House Winery Perry (MI)');
INSERT INTO "BjcpStyle" VALUES ('cider', 27, 'Standard Cider and Perry', '27E', 'Traditional Perry ', 'There is a pear character, but not obviously fruity. It tends toward that of a young white wine. Some slight bitterness.', 'Slightly cloudy to clear. Generally quite pale.', 'There is a pear character, but not obviously fruity. It tends toward that of a young white wine. Some slight bitterness.', 'Relatively full, moderate to high tannin apparent as astringency.', 'Tannic. Medium to medium-sweet. Still to lightly sparkling. Only very slight acetification is acceptable. Mousiness, ropy/oily characters are serious faults.', 'Entrants MUST specify carbonation level (still, petillant, or sparkling). Entrants MUST specify sweetness (medium or sweet). Variety of pear(s) used must be stated.', '', 1.05000000000000004, 1.07000000000000006, 1, 1.02000000000000002, NULL, NULL, NULL, NULL, 5, 9, '[France] Bordelet Poire Authentique and Poire Granit, Christian Drouin Poire, [UK] Gwatkin Blakeney Red Perry, Oliver''s Blakeney Red Perry and Herefordshire Dry Perry');
INSERT INTO "BjcpStyle" VALUES ('cider', 28, 'Specialty Cider and Perry', '28A', 'New England Cider', 'A dry flavorful cider with robust apple character, strong alcohol, and derivative flavors from sugar adjuncts.', 'to brilliant, pale to medium yellow. ', 'A dry flavorful cider with robust apple character, strong alcohol, and derivative flavors from sugar adjuncts', 'Substantial, alcoholic. Moderate tannin.', 'Substantial body and character .', 'Adjuncts may include white and brown sugars, molasses, small amounts of honey, and raisins. Adjuncts are intended to raise OG well above that which would be achieved by apples alone. This style is sometimes barrel-aged, in which case there will be oak character as with a barrel-aged wine. If the barrel was formerly used to age spirits, some flavor notes from the spirit (e.g., whisky or rum) may also be present, but must be subtle. Entrants MUST specify if the cider was barrel-fermented or aged. Entrants MUST specify carbonation level (still, petillant, or sparkling). Entrants MUST specify sweetness (dry, medium, or sweet).', '', 1.06000000000000005, 1.10000000000000009, 0.994999999999999996, 1.01000000000000001, NULL, NULL, NULL, NULL, 7, 13, 'There are no known commercial examples of New England Cider.');
INSERT INTO "BjcpStyle" VALUES ('cider', 28, 'Specialty Cider and Perry', '28B', 'Fruit Cider', 'The cider character must be present and must fit with the other fruits. It is a fault if the adjuncts completely dominate; a judge might ask, "Would this be different if neutral spirits replaced the cider?" A fruit cider should not be like an alco-pop. Oxidation is a fault.', 'Clear to brilliant. Color appropriate to added fruit, but should not show oxidation characteristics. (For example, berries should give red-to-purple color, not orange.)', 'The cider character must be present and must fit with the other fruits. It is a fault if the adjuncts completely dominate; a judge might ask, "Would this be different if neutral spirits replaced the cider?" A fruit cider should not be like an alco-pop. Oxidation is a fault.', 'Substantial. May be significantly tannic depending on fruit added.', 'Like a dry wine with complex flavors. The apple character must marry with the added fruit so that neither dominates the other. ', 'Entrants MUST specify carbonation level (still, petillant, or sparkling). Entrants MUST specify sweetness (dry or medium). Entrants MUST specify what fruit(s) and/or fruit juice(s) were added.', '', 1.04499999999999993, 1.07000000000000006, 0.994999999999999996, 1.01000000000000001, NULL, NULL, NULL, NULL, 5, 9, '[US] West County Blueberry-Apple Wine (MA), AEppelTreow Red Poll Cran-Apple Draft Cider (WI), Bellwether Cherry Street (NY), Uncle John''s Fruit Farm Winery Apple Cherry Hard Cider (MI)');
INSERT INTO "BjcpStyle" VALUES ('beer', 2, 'Pilsner', '2A', 'German Pilsner (Pils)', 'Typically features a light grainy Pils malt character (sometimes Graham cracker-like) and distinctive flowery or spicy noble hops.  Clean, no fruity esters, no diacetyl.  May have an initial sulfury aroma (from water and/or yeast) and a low background note of DMS (from Pils malt).', 'Straw to light gold, brilliant to very clear, with a creamy, long-lasting white head.', 'Crisp and bitter, with a dry to medium-dry finish.  Moderate to moderately-low yet well attenuated maltiness, although some grainy flavors and slight Pils malt sweetness are acceptable.  Hop bitterness dominates taste and continues through the finish and lingers into the aftertaste. Hop flavor can range from low to high but should only be derived from German noble hops.  Clean, no fruity esters, no diacetyl.', 'Medium-light body, medium to high carbonation.', 'Crisp, clean, refreshing beer that prominently features noble German hop bitterness accentuated by sulfates in the water.', 'Drier and crisper than a Bohemian Pilsener with a bitterness that tends to linger more in the aftertaste due to higher attenuation and higher-sulfate water.  Lighter in body and color, and with higher carbonation than a Bohemian Pilsener.  Modern examples of German Pilsners tend to become paler in color, drier in finish, and more bitter as you move from South to North in Germany.', 'Pilsner malt, German hop varieties (especially noble varieties such as Hallertauer, Tettnanger and Spalt for taste and aroma), medium sulfate water, German lager yeast.', 1.04400000000000004, 1.05000000000000004, 1.00800000000000001, 1.0129999999999999, 25, 45, 2, 5, 4.40000000000000036, 5.20000000000000018, 'Victory Prima Pils, Bitburger, Warsteiner, Trumer Pils, Old Dominion Tupper''s Hop Pocket Pils, KÃ¶nig Pilsener, Jever Pils, Left Hand Polestar Pilsner, Holsten Pils, Spaten Pils, Brooklyn Pilsner');
INSERT INTO "BjcpStyle" VALUES ('beer', 2, 'Pilsner', '2B', 'Bohemian Pilsener', 'Rich with complex malt and a spicy, floral Saaz hop bouquet. Some pleasant, restrained diacetyl is acceptable, but need not be present. Otherwise clean, with no fruity esters.', 'Very pale gold to deep burnished gold, brilliant to very clear, with a dense, long-lasting, creamy white head.', 'Rich, complex maltiness combined with a pronounced yet soft and rounded bitterness and spicy flavor from Saaz hops.  Some diacetyl is acceptable, but need not be present. Bitterness is prominent but never harsh, and does not linger. The aftertaste is balanced between malt and hops. Clean, no fruity esters.', 'Medium-bodied (although diacetyl, if present, may make it seem medium-full), medium carbonation.', 'Crisp, complex and well-rounded yet refreshing.', 'Uses Moravian malted barley and a decoction mash for rich, malt character.  Saaz hops and low sulfate, low carbonate water provide a distinctively soft, rounded hop profile.  Traditional yeast sometimes can provide a background diacetyl note.  Dextrins provide additional body, and diacetyl enhances the perception of a fuller palate.', 'Soft water with low mineral content, Saaz hops, Moravian malted barley, Czech lager yeast.', 1.04400000000000004, 1.05600000000000005, 1.0129999999999999, 1.0169999999999999, 35, 45, 3.5, 6, 4.20000000000000018, 5.40000000000000036, 'Pilsner Urquell, KruÅ¡ovice Imperial 12Â°, Budweiser Budvar (Czechvar in the US), Czech Rebel, Staropramen, Gambrinus Pilsner, Zlaty Bazant Golden Pheasant, Dock Street Bohemian Pilsner');
INSERT INTO "BjcpStyle" VALUES ('beer', 2, 'Pilsner', '2C', 'Classic American Pilsner', 'Low to medium grainy, corn-like or sweet maltiness may be evident (although rice-based beers are more neutral).  Medium to moderately high hop aroma, often classic noble hops.  Clean lager character, with no fruitiness or diacetyl.  Some DMS is acceptable.', 'Yellow to deep gold color.  Substantial, long lasting white head.  Bright clarity.', 'Moderate to moderately high maltiness similar in character to the Continental Pilsners but somewhat lighter in intensity due to the use of up to 30% flaked maize (corn) or rice used as an adjunct.  Slight grainy, corn-like sweetness from the use of maize with substantial offsetting hop bitterness.  Rice-based versions are crisper, drier, and often lack corn-like flavors.  Medium to high hop flavor from noble hops (either late addition or first-wort hopped).  Medium to high hop bitterness, which should not be coarse nor have a harsh aftertaste. No fruitiness or diacetyl.  Should be smooth and well-lagered.', 'Medium body and rich, creamy mouthfeel.  Medium to high carbonation levels.', 'A substantial Pilsner that can stand up to the classic European Pilsners, but exhibiting the native American grains and hops available to German brewers who initially brewed it in the USA.   Refreshing, but with the underlying malt and hops that stand out when compared to other modern American light lagers. Maize lends a distinctive grainy sweetness.  Rice contributes a crisper, more neutral character.', 'The classic American Pilsner was brewed both pre-Prohibition and post-Prohibition with some differences.  OGs of 1.050-1.060 would have been appropriate for pre-Prohibition beers while gravities dropped to 1.044-1.048 after Prohibition.  Corresponding IBUs dropped from a pre-Prohibition level of 30-40 to 25-30 after Prohibition.', 'Six-row barley with 20% to 30% flaked maize to dilute the excessive protein levels.  Native American hops such as Clusters, traditional continental noble hops, or modern noble crosses (Ultra, Liberty, Crystal) are also appropriate.  Modern American hops such as Cascade are inappropriate.  Water with a high mineral content can lead to an inappropriate coarseness in flavor and harshness in aftertaste.', 1.04400000000000004, 1.06000000000000005, 1.01000000000000001, 1.0149999999999999, 25, 40, 3, 6, 4.5, 6, 'Occasional brewpub and microbrewery specials');
INSERT INTO "BjcpStyle" VALUES ('beer', 3, 'European Amber Lager', '3A', 'Vienna Lager', 'Moderately rich German malt aroma (of Vienna and/or Munich malt).  A light toasted malt aroma may be present.  Similar, though less intense than Oktoberfest.  Clean lager character, with no fruity esters or diacetyl.  Noble hop aroma may be low to none.  Caramel aroma is inappropriate.', ': Light reddish amber to copper color. Bright clarity.  Large, off-white, persistent head.', 'Soft, elegant malt complexity is in the forefront, with a firm enough hop bitterness to provide a balanced finish. Some toasted character from the use of Vienna malt.  No roasted or caramel flavor.  Fairly dry finish, with both malt and hop bitterness present in the aftertaste.  Noble hop flavor may be low to none.', 'Medium-light to medium body, with a gentle creaminess.  Moderate carbonation.  Smooth.  Moderately crisp finish.  May have a bit of alcohol warming.', 'Characterized by soft, elegant maltiness that dries out in the finish to avoid becoming sweet.', 'American versions can be a bit stronger, drier and more bitter, while European versions tend to be sweeter.  Many Mexican amber and dark lagers used to be more authentic, but unfortunately are now more like sweet, adjunct-laden American Dark Lagers.  ', 'Vienna malt provides a lightly toasty and complex, melanoidin-rich malt profile.  As with Oktoberfests, only the finest quality malt should be used, along with Continental hops (preferably noble varieties).  Moderately hard, carbonate-rich water.  Can use some caramel malts and/or darker malts to add color and sweetness, but caramel malts shouldn''t add significant aroma and flavor and dark malts shouldn''t provide any roasted character.', 1.04600000000000004, 1.05200000000000005, 1.01000000000000001, 1.01400000000000001, 18, 30, 10, 16, 4.5, 5.5, 'Great Lakes Eliot Ness (unusual in its 6.2% strength and 35 IBUs), Boulevard Bobs 47 Munich-Style Lager, Negra Modelo, Old Dominion Aviator Amber Lager, Gordon Biersch Vienna Lager, Capital Wisconsin Amber, Olde Saratoga Lager, Penn Pilsner');
INSERT INTO "BjcpStyle" VALUES ('beer', 3, 'European Amber Lager', '3B', 'Oktoberfest/Marzen', 'Rich German malt aroma (of Vienna and/or Munich malt).  A light to moderate toasted malt aroma is often present.  Clean lager aroma with no fruity esters or diacetyl.  No hop aroma.  Caramel aroma is inappropriate.', 'Dark gold to deep orange-red color. Bright clarity, with solid, off-white, foam stand.', 'Initial malty sweetness, but finish is moderately dry.  Distinctive and complex maltiness often includes a toasted aspect.  Hop bitterness is moderate, and noble hop flavor is low to none. Balance is toward malt, though the finish is not sweet.  Noticeable caramel or roasted flavors are inappropriate.  Clean lager character with no diacetyl or fruity esters.', 'Medium body, with a creamy texture and medium carbonation.  Smooth.  Fully fermented, without a cloying finish.', 'Smooth, clean, and rather rich, with a depth of malt character.  This is one of the classic malty styles, with a maltiness that is often described as soft, complex, and elegant but never cloying.', 'Domestic German versions tend to be golden, like a strong Pils-dominated Helles.  Export German versions are typically orange-amber in color, and have a distinctive toasty malt character.  German beer tax law limits the OG of the style at 14Â°P since it is a vollbier, although American versions can be stronger.  "Fest" type beers are special occasion beers that are usually stronger than their everyday counterparts.', 'Grist varies, although German Vienna malt is often the backbone of the grain bill, with some Munich malt, Pils malt, and possibly some crystal malt. All malt should derive from the finest quality two-row barley. Continental hops, especially noble varieties, are most authentic.  Somewhat alkaline water (up to 300 PPM), with significant carbonate content is welcome.  A decoction mash can help develop the rich malt profile.', 1.05000000000000004, 1.05699999999999994, 1.01200000000000001, 1.01600000000000001, 20, 28, 7, 14, 4.79999999999999982, 5.70000000000000018, 'Paulaner Oktoberfest, Ayinger Oktoberfest-MÃ¤rzen, Hacker-Pschorr Original Oktoberfest, HofbrÃ¤u Oktoberfest, Victory Festbier, Great Lakes Oktoberfest, Spaten Oktoberfest, Capital Oktoberfest, Gordon Biersch MÃ¤rzen, Goose Island Oktoberfest, Samuel Adams Oktoberfest (a bit unusual in its late hopping)');
INSERT INTO "BjcpStyle" VALUES ('beer', 4, 'Dark Lager', '4A', 'Dark American Lager', 'Little to no malt aroma.  Medium-low to no roast and caramel malt aroma.  Hop aroma may range from none to light spicy or floral hop presence.  Can have low levels of yeast character (green apples, DMS, or fruitiness).  No diacetyl.', 'Deep amber to dark brown with bright clarity and ruby highlights.  Foam stand may not be long lasting, and is usually light tan in color.', 'Moderately crisp with some low to moderate levels of sweetness.  Medium-low to no caramel and/or roasted malt flavors (and may include hints of coffee, molasses or cocoa).  Hop flavor ranges from none to low levels.  Hop bitterness at low to medium levels.  No diacetyl.  May have a very light fruitiness.  Burnt or moderately strong roasted malt flavors are a defect.', 'Light to somewhat medium body.  Smooth, although a highly-carbonated beer.', 'A somewhat sweeter version of standard/premium lager with a little more body and flavor.', 'A broad range of international lagers that are darker than pale, and not assertively bitter and/or roasted.', 'Two- or six-row barley, corn or rice as adjuncts.  Light use of caramel and darker malts.  Commercial versions may use coloring agents.', 1.04400000000000004, 1.05600000000000005, 1.00800000000000001, 1.01200000000000001, 8, 20, 14, 22, 4.20000000000000018, 6, 'Dixie Blackened Voodoo, Shiner Bock, San Miguel Dark, Baltika #4, Beck''s Dark, Saint Pauli Girl Dark, Warsteiner Dunkel, Heineken Dark Lager, Crystal Diplomat Dark Beer');
INSERT INTO "BjcpStyle" VALUES ('beer', 4, 'Dark Lager', '4B', 'Munich Dunkel', 'Rich, Munich malt sweetness, like bread crusts (and sometimes toast.)  Hints of chocolate, nuts, caramel, and/or toffee are also acceptable.  No fruity esters or diacetyl should be detected, but a slight noble hop aroma is acceptable.', 'Deep copper to dark brown, often with a red or garnet tint.  Creamy, light to medium tan head.  Usually clear, although murky unfiltered versions exist.', 'Dominated by the rich and complex flavor of Munich malt, usually with melanoidins reminiscent of bread crusts.  The taste can be moderately sweet, although it should not be overwhelming or cloying.  Mild caramel, chocolate, toast or nuttiness may be present.  Burnt or bitter flavors from roasted malts are inappropriate, as are pronounced caramel flavors from crystal malt. Hop bitterness is moderately low but perceptible, with the balance tipped firmly towards maltiness.  Noble hop flavor is low to none. Aftertaste remains malty, although the hop bitterness may become more apparent in the medium-dry finish.  Clean lager character with no fruity esters or diacetyl.', 'Medium to medium-full body, providing a firm and dextrinous mouthfeel without being heavy or cloying.  Moderate carbonation.  May have a light astringency and a slight alcohol warming.', 'Characterized by depth and complexity of Munich malt and the accompanying melanoidins.  Rich Munich flavors, but not as intense as a bock or as roasted as a schwarzbier.', 'Unfiltered versions from Germany can taste like liquid bread, with a yeasty, earthy richness not found in exported filtered dunkels.', 'Grist is traditionally made up of German Munich malt (up to 100% in some cases) with the remainder German Pilsner malt.  Small amounts of crystal malt can add dextrins and color but should not introduce excessive residual sweetness. Slight additions of roasted malts (such as Carafa or chocolate) may be used to improve color but should not add strong flavors.  Noble German hop varieties and German lager yeast strains should be used.  Moderately carbonate water.  Often decoction mashed (up to a triple decoction) to enhance the malt flavors and create the depth of color.', 1.04800000000000004, 1.05600000000000005, 1.01000000000000001, 1.01600000000000001, 18, 28, 14, 28, 4.5, 5.59999999999999964, 'Ayinger Altbairisch Dunkel, Hacker-Pschorr Alt Munich Dark, Paulaner Alt MÃ¼nchner Dunkel, Weltenburger Kloster Barock-Dunkel, Ettaler Kloster Dunkel, HofbrÃ¤u Dunkel, Penn Dark Lager, KÃ¶nig Ludwig Dunkel, Capital Munich Dark, Harpoon Munich-type Dark Beer, Gordon Biersch Dunkels, Dinkel Acker Dark.  In Bavaria, Ettaler Dunkel, LÃ¶wenbrÃ¤u Dunkel, Hartmann Dunkel, Kneitinger Dunkel, Augustiner Dunkel.');
INSERT INTO "BjcpStyle" VALUES ('beer', 4, 'Dark Lager', '4C', 'Schwarzbier (Black Beer)', 'Low to moderate malt, with low aromatic sweetness and/or hints of roast malt often apparent.  The malt can be clean and neutral or rich and Munich-like, and may have a hint of caramel.  The roast can be coffee-like but should never be burnt.  A low noble hop aroma is optional. Clean lager yeast character (light sulfur possible) with no fruity esters or diacetyl.', 'Medium to very dark brown in color, often with deep ruby to garnet highlights, yet almost never truly black.  Very clear.  Large, persistent, tan-colored head.', 'Light to moderate malt flavor, which can have a clean, neutral character to a rich, sweet, Munich-like intensity.  Light to moderate roasted malt flavors can give a bitter-chocolate palate that lasts into the finish, but which are never burnt.  Medium-low to medium bitterness, which can last into the finish.  Light to moderate noble hop flavor.  Clean lager character with no fruity esters or diacetyl.  Aftertaste tends to dry out slowly and linger, featuring hop bitterness with a complementary but subtle roastiness in the background.  Some residual sweetness is acceptable but not required.', 'Medium-light to medium body.  Moderate to moderately high carbonation.  Smooth.  No harshness or astringency, despite the use of dark, roasted malts.', 'A dark German lager that balances roasted yet smooth malt flavors with moderate hop bitterness.', 'In comparison with a Munich Dunkel, usually darker in color, drier on the palate and with a noticeable (but not high) roasted malt edge to balance the malt base.  While sometimes called a "black Pils," the beer is rarely that dark; don''t expect strongly roasted, porter-like flavors.', 'German Munich malt and Pilsner malts for the base, supplemented by a small amount of roasted malts (such as Carafa) for the dark color and subtle roast flavors.  Noble-type German hop varieties and clean German lager yeasts are preferred.', 1.04600000000000004, 1.05200000000000005, 1.01000000000000001, 1.01600000000000001, 22, 32, 17, 30, 4.40000000000000036, 5.40000000000000036, 'KÃ¶stritzer Schwarzbier, Kulmbacher MÃ¶nchshof Premium Schwarzbier, Samuel Adams Black Lager, KruÅ¡ovice Cerne, Original Badebier, Einbecker Schwarzbier, Gordon Biersch Schwarzbier, Weeping Radish Black Radish Dark Lager, Sprecher Black Bavarian');
INSERT INTO "BjcpStyle" VALUES ('beer', 5, 'Bock', '5A', 'Maibock/Helles Bock', 'Moderate to strong malt aroma, often with a lightly toasted quality and low melanoidins.  Moderately low to no noble hop aroma, often with a spicy quality.  Clean.  No diacetyl.  Fruity esters should be low to none. Some alcohol may be noticeable.  May have a light DMS aroma from Pils malt.', 'Deep gold to light amber in color.  Lagering should provide good clarity.  Large, creamy, persistent, white head.', 'The rich flavor of continental European pale malts dominates (Pils malt flavor with some toasty notes and/or melanoidins). Little to no caramelization.  May have a light DMS flavor from Pils malt.  Moderate to no noble hop flavor.  May have a low spicy or peppery quality from hops and/or alcohol.  Moderate hop bitterness (more so in the balance than in other bocks).  Clean, with no fruity esters or diacetyl.  Well-attenuated, not cloying, with a moderately dry finish that may taste of both malt and hops.', 'Medium-bodied.  Moderate to moderately high carbonation.  Smooth and clean with no harshness or astringency, despite the increased hop bitterness.  Some alcohol warming may be present.', 'A relatively pale, strong, malty lager beer.  Designed to walk a fine line between blandness and too much color.  Hop character is generally more apparent than in other bocks.', 'Can be thought of as either a pale version of a traditional bock, or a Munich helles brewed to bock strength.  While quite malty, this beer typically has less dark and rich malt flavors than a traditional bock.  May also be drier, hoppier, and more bitter than a traditional bock.  The hops compensate for the lower level of melanoidins.  There is some dispute whether Helles ("pale") Bock and Mai ("May") Bock are synonymous.  Most agree that they are identical (as is the consensus for MÃ¤rzen and Oktoberfest), but some believe that Maibock is a "fest" type beer hitting the upper limits of hopping and color for the range. Any fruitiness is due to Munich and other specialty malts, not yeast-derived esters developed during fermentation.', 'Base of Pils and/or Vienna malt with some Munich malt to add character (although much less than in a traditional bock).  No non-malt adjuncts.  Noble hops.  Soft water preferred so as to avoid harshness.  Clean lager yeast.  Decoction mash is typical, but boiling is less than in traditional bocks to restrain color development.', 1.06400000000000006, 1.07200000000000006, 1.0109999999999999, 1.01800000000000002, 23, 35, 6, 11, 6.29999999999999982, 7.40000000000000036, 'Ayinger Maibock, Mahr''s Bock, Hacker-Pschorr Hubertus Bock, Capital Maibock, Einbecker Mai-Urbock, HofbrÃ¤u Maibock, Victory St. Boisterous, Gordon Biersch Blonde Bock, Smuttynose Maibock');
INSERT INTO "BjcpStyle" VALUES ('beer', 5, 'Bock', '5B', 'Traditional Bock', 'Strong malt aroma, often with moderate amounts of rich melanoidins and/or toasty overtones.  Virtually no hop aroma.  Some alcohol may be noticeable.  Clean.  No diacetyl.  Low to no fruity esters. ', 'Light copper to brown color, often with attractive garnet highlights.  Lagering should provide good clarity despite the dark color.  Large, creamy, persistent, off-white head.', 'Complex maltiness is dominated by the rich flavors of Munich and Vienna malts, which contribute melanoidins and toasty flavors.  Some caramel notes may be present from decoction mashing and a long boil.  Hop bitterness is generally only high enough to support the malt flavors, allowing a bit of sweetness to linger into the finish.  Well-attenuated, not cloying.  Clean, with no esters or diacetyl. No hop flavor.  No roasted or burnt character.', 'Medium to medium-full bodied.  Moderate to moderately low carbonation.  Some alcohol warmth may be found, but should never be hot.  Smooth, without harshness or astringency.', 'A dark, strong, malty lager beer.', 'Decoction mashing and long boiling plays an important part of flavor development, as it enhances the caramel and melanoidin flavor aspects of the malt.  Any fruitiness is due to Munich and other specialty malts, not yeast-derived esters developed during fermentation.', 'Munich and Vienna malts, rarely a tiny bit of dark roasted malts for color adjustment, never any non-malt adjuncts.  Continental European hop varieties are used.  Clean lager yeast.  Water hardness can vary, although moderately carbonate water is typical of Munich.  ', 1.06400000000000006, 1.07200000000000006, 1.0129999999999999, 1.01899999999999991, 20, 27, 14, 22, 6.29999999999999982, 7.20000000000000018, 'Einbecker Ur-Bock Dunkel, Pennsylvania Brewing St. Nick Bock, Aass Bock, Great Lakes Rockefeller Bock, Stegmaier Brewhouse Bock');
INSERT INTO "BjcpStyle" VALUES ('beer', 5, 'Bock', '5C', 'Doppelbock', 'Very strong maltiness.  Darker versions will have significant melanoidins and often some toasty aromas.  A light caramel flavor from a long boil is acceptable.  Lighter versions will have a strong malt presence with some melanoidins and toasty notes.  Virtually no hop aroma, although a light noble hop aroma is acceptable in pale versions.  No diacetyl.  A moderately low fruity aspect to the aroma often described as prune, plum or grape may be present (but is optional) in dark versions due to reactions between malt, the boil, and aging.  A very slight chocolate-like aroma may be present in darker versions, but no roasted or burned aromatics should ever be present.  Moderate alcohol aroma may be present.', 'Deep gold to dark brown in color.  Darker versions often have ruby highlights.  Lagering should provide good clarity.  Large, creamy, persistent head (color varies with base style: white for pale versions, off-white for dark varieties).  Stronger versions might have impaired head retention, and can display noticeable legs.', 'Very rich and malty.  Darker versions will have significant melanoidins and often some toasty flavors.  Lighter versions will a strong malt flavor with some melanoidins and toasty notes.  A very slight chocolate flavor is optional in darker versions, but should never be perceived as roasty or burnt.  Clean lager flavor with no diacetyl.  Some fruitiness (prune, plum or grape) is optional in darker versions.   Invariably there will be an impression of alcoholic strength, but this should be smooth and warming rather than harsh or burning.  Presence of higher alcohols (fusels) should be very low to none.  Little to no hop flavor (more is acceptable in pale versions).  Hop bitterness varies from moderate to moderately low but always allows malt to dominate the flavor.  Most versions are fairly sweet, but should have an impression of attenuation.  The sweetness comes from low hopping, not from incomplete fermentation.  Paler versions generally have a drier finish.', 'Medium-full to full body.  Moderate to moderately-low carbonation.  Very smooth without harshness or astringency.', 'A very strong and rich lager.  A bigger version of either a traditional bock or a helles bock.', 'Most versions are dark colored and may display the caramelizing and melanoidin effect of decoction mashing, but excellent pale versions also exist.  The pale versions will not have the same richness and darker malt flavors of the dark versions, and may be a bit drier, hoppier and more bitter.  While most traditional examples are in the ranges cited, the style can be considered to have no upper limit for gravity, alcohol and bitterness (thus providing a home for very strong lagers). Any fruitiness is due to Munich and other specialty malts, not yeast-derived esters developed during fermentation.', 'Pils and/or Vienna malt for pale versions (with some Munich), Munich and Vienna malts for darker ones and occasionally a tiny bit of darker color malts (such as Carafa).  Noble hops.  Water hardness varies from soft to moderately carbonate.  Clean lager yeast.  Decoction mashing is traditional.', 1.07200000000000006, 1.1120000000000001, 1.01600000000000001, 1.02400000000000002, 16, 26, 6, 25, 7, 10, 'Paulaner Salvator, Ayinger Celebrator, Weihenstephaner Korbinian, Andechser Doppelbock Dunkel, Spaten Optimator, Tucher Bajuvator, Weltenburger Kloster Asam-Bock, Capital Autumnal Fire, EKU 28, Eggenberg Urbock 23Â°, Bell''s Consecrator, Moretti La Rossa, Samuel Adams Double Bock');
INSERT INTO "BjcpStyle" VALUES ('beer', 5, 'Bock', '5D', 'Eisbock', 'Dominated by a balance of rich, intense malt and a definite alcohol presence.  No hop aroma.  No diacetyl.  May have significant fruity esters, particularly those reminiscent of plum, prune or grape.  Alcohol aromas should not be harsh or solventy.', 'Deep copper to dark brown in color, often with attractive ruby highlights.  Lagering should provide good clarity.  Head retention may be impaired by higher-than-average alcohol content and low carbonation.  Off-white to deep ivory colored head. Pronounced legs are often evident.', 'Rich, sweet malt balanced by a significant alcohol presence.  The malt can have melanoidins, toasty qualities, some caramel, and occasionally a slight chocolate flavor.  No hop flavor.  Hop bitterness just offsets the malt sweetness enough to avoid a cloying character. No diacetyl.  May have significant fruity esters, particularly those reminiscent of plum, prune or grape.  The alcohol should be smooth, not harsh or hot, and should help the hop bitterness balance the strong malt presence.  The finish should be of malt and alcohol, and can have a certain dryness from the alcohol.  It should not by sticky, syrupy or cloyingly sweet.  Clean, lager character.', 'Full to very full bodied.  Low carbonation.  Significant alcohol warmth without sharp hotness.  Very smooth without harsh edges from alcohol, bitterness, fusels, or other concentrated flavors.', 'An extremely strong, full and malty dark lager.', 'Eisbocks are not simply stronger doppelbocks; the name refers to the process of freezing and concentrating the beer.  Some doppelbocks are stronger than Eisbocks.  Extended lagering is often needed post-freezing to smooth the alcohol and enhance the malt and alcohol balance.  Any fruitiness is due to Munich and other specialty malts, not yeast-derived esters developed during fermentation.', 'Same as doppelbock.  Commercial eisbocks are generally concentrated anywhere from 7% to 33% (by volume).', 1.07800000000000007, 1.12000000000000011, 1.02000000000000002, 1.03499999999999992, 25, 35, 18, 30, 9, 14, 'Kulmbacher ReichelbrÃ¤u Eisbock, Eggenberg Urbock Dunkel Eisbock, Niagara Eisbock, Capital Eisphyre, Southampton Eisbock');
INSERT INTO "BjcpStyle" VALUES ('beer', 6, 'Light Hybrid Beer', '6A', 'Cream Ale', 'Faint malt notes.  A sweet, corn-like aroma and low levels of DMS are commonly found.  Hop aroma low to none.  Any variety of hops may be used, but neither hops nor malt dominate.  Faint esters may be present in some examples, but are not required.  No diacetyl.', 'Pale straw to moderate gold color, although usually on the pale side.  Low to medium head with medium to high carbonation.  Head retention may be no better than fair due to adjunct use.  Brilliant, sparkling clarity.', 'Low to medium-low hop bitterness. Low to moderate maltiness and sweetness, varying with gravity and attenuation.  Usually well attenuated.  Neither malt nor hops prevail in the taste.  A low to moderate corny flavor from corn adjuncts is commonly found, as is some DMS.  Finish can vary from somewhat dry to faintly sweet from the corn, malt, and sugar.  Faint fruity esters are optional.  No diacetyl.', 'Generally light and crisp, although body can reach medium.  Smooth mouthfeel with medium to high attenuation; higher attenuation levels can lend a "thirst quenching" finish.  High carbonation.  Higher gravity examples may exhibit a slight alcohol warmth.', 'A clean, well-attenuated, flavorful American lawnmower beer.', 'Classic American (i.e., pre-prohibition) Cream Ales were slightly stronger, hoppier (including some dry hopping) and more bitter (25-30+ IBUs).  These versions should be entered in the specialty/experimental category.  Most commercial examples are in the 1.050-1.053 OG range, and bitterness rarely rises above 20 IBUs.', 'American ingredients most commonly used.  A grain bill of six-row malt, or a combination of six-row and North American two-row, is common.  Adjuncts can include up to 20% flaked maize in the mash, and up to 20% glucose or other sugars in the boil.  Soft water preferred.  Any variety of hops can be used for bittering and finishing.', 1.04200000000000004, 1.05499999999999994, 1.00600000000000001, 1.01200000000000001, 15, 20, 3, 5, 4.20000000000000018, 5.59999999999999964, 'Genesee Cream Ale, Little Kings Cream Ale (Hudepohl), Anderson Valley Summer Solstice Cerveza Crema, Sleeman Cream Ale, New Glarus Spotted Cow, Wisconsin Brewing Whitetail Cream Ale');
INSERT INTO "BjcpStyle" VALUES ('beer', 6, 'Light Hybrid Beer', '6B', 'Blonde Ale', 'Light to moderate sweet malty aroma.  Low to moderate fruitiness is optional, but acceptable.  May have a low to medium hop aroma, and can reflect almost any hop variety.  No diacetyl.', 'Light yellow to deep gold in color.  Clear to brilliant.  Low to medium white head with fair to good retention.', 'Initial soft malty sweetness, but optionally some light character malt flavor (e.g., bread, toast, biscuit, wheat) can also be present.  Caramel flavors typically absent.  Low to medium esters optional, but are commonly found in many examples.  Light to moderate hop flavor (any variety), but shouldn''t be overly aggressive.  Low to medium bitterness, but the balance is normally towards the malt.  Finishes medium-dry to somewhat sweet.  No diacetyl.', 'Medium-light to medium body.  Medium to high carbonation.  Smooth without harsh bitterness or astringency.', 'Easy-drinking, approachable, malt-oriented American craft beer.', 'In addition to the more common American Blonde Ale, this category can also include modern English Summer Ales, American KÃ¶lsch-style beers, and less assertive American and English pale ales.', 'Generally all malt, but can include up to 25% wheat malt and some sugar adjuncts.  Any hop variety can be used.  Clean American, lightly fruity English, or KÃ¶lsch yeast.  May also be made with lager yeast, or cold-conditioned.  Some versions may have honey, spices and/or fruit added, although if any of these ingredients are stronger than a background flavor they should be entered in specialty, spiced or fruit beer categories instead.  Extract versions should only use the lightest malt extracts and avoid kettle caramelization.', 1.03800000000000003, 1.05400000000000005, 1.00800000000000001, 1.0129999999999999, 15, 28, 3, 6, 3.79999999999999982, 5.5, 'Pelican Kiwanda Cream Ale, Russian River Aud Blonde, Rogue Oregon Golden Ale, Widmer Blonde Ale, Fuller''s Summer Ale, Hollywood Blonde, Redhook Blonde');
INSERT INTO "BjcpStyle" VALUES ('beer', 6, 'Light Hybrid Beer', '6C', 'Kölsch', 'Very low to no Pils malt aroma.  A pleasant, subtle fruit aroma from fermentation (apple, cherry or pear) is acceptable, but not always present.  A low noble hop aroma is optional but not out of place (it is present only in a small minority of authentic versions).  Some yeasts may give a slight winy or sulfury character (this characteristic is also optional, but not a fault).', 'Very pale gold to light gold.  Authentic versions are filtered to a brilliant clarity.  Has a delicate white head that may not persist.', 'Soft, rounded palate comprising of a delicate flavor balance between soft yet attenuated malt, an almost imperceptible fruity sweetness from fermentation, and a medium-low to medium bitterness with a delicate dryness and slight pucker in the finish (but no harsh aftertaste).  The noble hop flavor is variable, and can range from low to moderately high; most are medium-low to medium.  One or two examples (Dom being the most prominent) are noticeably malty-sweet up front.  Some versions can have a slightly minerally or sulfury water or yeast character that accentuates the dryness and flavor balance. Some versions may have a slight wheat taste, although this is quite rare.  Otherwise very clean with no diacetyl or fusels.', 'Smooth and crisp.  Medium-light body, although a few versions may be medium.  Medium to medium-high carbonation.  Generally well-attenuated.', 'A clean, crisp, delicately balanced beer usually with very subtle fruit flavors and aromas.  Subdued maltiness throughout leads to a pleasantly refreshing tang in the finish.  To the untrained taster easily mistaken for a light lager, a somewhat subtle Pilsner, or perhaps a blonde ale.', 'Served in a tall, narrow 200ml glass called a "Stange."  Each KÃ¶ln brewery produces a beer of different character, and each interprets the Konvention slightly differently.  Allow for a range of variation within the style when judging.  Note that drier versions may seem hoppier or more bitter than the IBU specifications might suggest.  Due to its delicate flavor profile, KÃ¶lsch tends to have a relatively short shelf-life; older examples can show some oxidation defects.  Some KÃ¶ln breweries (e.g., Dom, Hellers) are now producing young, unfiltered versions known as Wiess (which should not be entered in this category).', 'German noble hops (Hallertau, Tettnang, Spalt or Hersbrucker).  German Pils or pale malt.  Attenuative, clean ale yeast.  Up to 20% wheat may be used, but this is quite rare in authentic versions.  Water can vary from extremely soft to moderately hard.  Traditionally uses a step mash program, although good results can be obtained using a single rest at 149Â°F.  Fermented at cool ale temperatures (59-65Â°F) and lagered for at least a month, although many Cologne brewers ferment at 70Â°F and lager for no more than two weeks.', 1.04400000000000004, 1.05000000000000004, 1.0069999999999999, 1.0109999999999999, 20, 30, 4, 5, 4.40000000000000036, 5.20000000000000018, 'Available in Cologne only: PJ FrÃ¼h, Hellers, MalzmÃ¼hle, Paeffgen, Sion, Peters, Dom; import versions available in parts of North America: Reissdorf, Gaffel; Non-German versions: Eisenbahn Dourada, Goose Island Summertime, Alaska Summer Ale, Harpoon Summer Beer, New Holland Lucid, Saint Arnold Fancy Lawnmower, Capitol City Capitol KÃ¶lsch, Shiner KÃ¶lsch');
INSERT INTO "BjcpStyle" VALUES ('beer', 6, 'Light Hybrid Beer', '6D', 'American Wheat or Rye Beer', 'Low to moderate grainy wheat or rye character.  Some malty sweetness is acceptable.  Esters can be moderate to none, although should reflect American yeast strains.  The clove and banana aromas common to German hefeweizens are inappropriate.  Hop aroma may be low to moderate, and can have either a citrusy American or a spicy or floral noble hop character.  Slight crisp sharpness is optional.  No diacetyl.', 'Usually pale yellow to gold.  Clarity may range from brilliant to hazy with yeast approximating the German hefeweizen style of beer.  Big, long-lasting white head.', 'Light to moderately strong grainy wheat or rye flavor, which can linger into the finish.  Rye versions are richer and spicier than wheat.  May have a moderate malty sweetness or finish quite dry.  Low to moderate hop bitterness, which sometimes lasts into the finish.  Low to moderate hop flavor (citrusy American or spicy/floral noble).  Esters can be moderate to none, but should not take on a German Weizen character (banana).  No clove phenols, although a light spiciness from wheat or rye is acceptable.  May have a slightly crisp or sharp finish.  No diacetyl.', 'Medium-light to medium body.  Medium-high to high carbonation.  May have a light alcohol warmth in stronger examples.', 'Refreshing wheat or rye beers that can display more hop character and less yeast character than their German cousins.', 'Different variations exist, from an easy-drinking fairly sweet beer to a dry, aggressively hopped beer with a strong wheat or rye flavor.  Dark versions approximating dunkelweizens (with darker, richer malt flavors in addition to the color) should be entered in the Specialty Beer category. THE BREWER SHOULD SPECIFY IF RYE IS USED; IF NO DOMINANT GRAIN IS SPECIFIED, WHEAT WILL BE ASSUMED.', 'Clean American ale yeast, but also can be made as a lager. Large proportion of wheat malt (often 50% or more, but this isn''t a legal requirement as in Germany).  American or noble hops.  American Rye Beers can follow the same general guidelines, substituting rye for some or all of the wheat.  Other base styles (e.g., IPA, stout) with a noticeable rye character should be entered in the Specialty Beer category (23).', 1.04000000000000004, 1.05499999999999994, 1.00800000000000001, 1.0129999999999999, 15, 30, 3, 6, 4, 5.5, 'Bell''s Oberon, Harpoon UFO Hefeweizen, Three Floyds Gumballhead, Pyramid Hefe-Weizen, Widmer Hefeweizen, Sierra Nevada Unfiltered Wheat Beer, Anchor Summer Beer, Redhook Sunrye, Real Ale Full Moon Pale Rye');
INSERT INTO "BjcpStyle" VALUES ('beer', 7, 'Amber Hybrid Beer', '7A', 'Northern German Altbier', 'Subtle malty, sometimes grainy aroma.  Low to no noble hop aroma.  Clean, lager character with very restrained ester profile.  No diacetyl.', 'Light copper to light brown color; very clear from extended cold conditioning. Low to moderate off-white to white head with good retention.', 'Fairly bitter yet balanced by a smooth and sometimes sweet malt character that may have a rich, biscuity and/or lightly caramelly flavor.  Dry finish often with lingering bitterness.  Clean, lager character sometimes with slight sulfury notes and very low to no esters.  Very low to medium noble hop flavor.  No diacetyl.', 'Medium-light to medium body.  Moderate to moderately high carbonation.  Smooth mouthfeel.', 'A very clean and relatively bitter beer, balanced by some malt character.  Generally darker, sometimes more caramelly, and usually sweeter and less bitter than DÃ¼sseldorf Altbier.', 'Most Altbiers produced outside of DÃ¼sseldorf are of the Northern German style.   Most are simply moderately bitter brown lagers.  Ironically "alt" refers to the old style of brewing (i.e., making ales), which makes the term "Altbier" somewhat inaccurate and inappropriate.  Those that are made as ales are fermented at cool ale temperatures and lagered at cold temperatures (as with DÃ¼sseldorf Alt).', 'Typically made with a Pils base and colored with roasted malt or dark crystal.  May include small amounts of Munich or Vienna malt.  Noble hops.  Usually made with an attenuative lager yeast.', 1.04600000000000004, 1.05400000000000005, 1.01000000000000001, 1.0149999999999999, 25, 40, 13, 19, 4.5, 5.20000000000000018, 'DAB Traditional, Hannen Alt, Schwelmer Alt, Grolsch Amber, Alaskan Amber, Long Trail Ale, Otter Creek Copper Ale, Schmaltz'' Alt');
INSERT INTO "BjcpStyle" VALUES ('beer', 7, 'Amber Hybrid Beer', '7B', 'California Common Beer', 'Typically showcases the signature Northern Brewer hops (with woody, rustic or minty qualities) in moderate to high strength.  Light fruitiness acceptable.  Low to moderate caramel and/or toasty malt aromatics support the hops.  No diacetyl.', 'Medium amber to light copper color.  Generally clear.  Moderate off-white head with good retention.', 'Moderately malty with a pronounced hop bitterness.  The malt character is usually toasty (not roasted) and caramelly.  Low to moderately high hop flavor, usually showing Northern Brewer qualities (woody, rustic, minty).  Finish fairly dry and crisp, with a lingering hop bitterness and a firm, grainy malt flavor.  Light fruity esters are acceptable, but otherwise clean.  No diacetyl.', 'Medium-bodied.  Medium to medium-high carbonation.', 'A lightly fruity beer with firm, grainy maltiness, interesting toasty and caramel flavors, and showcasing the signature Northern Brewer varietal hop character.', 'This style is narrowly defined around the prototypical Anchor Steam example.  Superficially similar to an American pale or amber ale, yet differs in that the hop flavor/aroma is woody/minty rather than citrusy, malt flavors are toasty and caramelly, the hopping is always assertive, and a warm-fermented lager yeast is used.', 'Pale ale malt, American hops (usually Northern Brewer, rather than citrusy varieties), small amounts of toasted malt and/or crystal malts.  Lager yeast, however some strains (often with the mention of "California" in the name) work better than others at the warmer fermentation temperatures (55 to 60Â°F) used.  Note that some German yeast strains produce inappropriate sulfury character.  Water should have relatively low sulfate and low to moderate carbonate levels.', 1.04800000000000004, 1.05400000000000005, 1.0109999999999999, 1.01400000000000001, 30, 45, 10, 14, 4.5, 5.5, 'Anchor Steam, Southampton Steem Beer, Flying Dog Old Scratch Amber Lager');
INSERT INTO "BjcpStyle" VALUES ('beer', 7, 'Amber Hybrid Beer', '7C', 'Düsseldorf Altbier', 'Clean yet robust and complex aroma of rich malt, noble hops and restrained fruity esters.  The malt character reflects German base malt varieties.  The hop aroma may vary from moderate to very low, and can have a peppery, floral or perfumy character associated with noble hops.  No diacetyl.', 'Light amber to orange-bronze to deep copper color, yet stopping short of brown.  Brilliant clarity (may be filtered). Thick, creamy, long-lasting off-white head.', 'Assertive hop bitterness well balanced by a sturdy yet clean and crisp malt character.  The malt presence is moderated by moderately-high to high attenuation, but considerable rich and complex malt flavors remain.  Some fruity esters may survive the lagering period.  A long-lasting, medium-dry to dry, bittersweet or nutty finish reflects both the hop bitterness and malt complexity.  Noble hop flavor can be moderate to low.  No roasted malt flavors or harshness.  No diacetyl.  Some yeast strains may impart a slight sulfury character.  A light minerally character is also sometimes present in the finish, but is not required.  The apparent bitterness level is sometimes masked by the high malt character; the bitterness can seem as low as moderate if the finish is not very dry.', 'Medium-bodied.  Smooth.  Medium to medium-high carbonation.  Astringency low to none.  Despite being very full of flavor, is light bodied enough to be consumed as a session beer in its home brewpubs in DÃ¼sseldorf.', 'A well balanced, bitter yet malty, clean, smooth, well-attenuated amber-colored German ale.', 'A bitter beer balanced by a pronounced malt richness.  Fermented at cool ale temperature (60-65Â°F), and lagered at cold temperatures to produce a cleaner, smoother palate than is typical for most ales.   Common variants include Sticke ("secret") alt, which is slightly stronger, darker, richer and more complex than typical alts.  Bitterness rises up to 60 IBUs and is usually dry hopped and lagered for a longer time.  MÃ¼nster alt is typically lower in gravity and alcohol, sour, lighter in color (golden), and can contain a significant portion of wheat.  Both Sticke alt and MÃ¼nster alt should be entered in the specialty category.', 'Grists vary, but usually consist of German base malts (usually Pils, sometimes Munich) with small amounts of crystal, chocolate, and/or black malts used to adjust color.  Occasionally will include some wheat.  Spalt hops are traditional, but other noble hops can also be used.  Moderately carbonate water.  Clean, highly attenuative ale yeast.  A step mash or decoction mash program is traditional.', 1.04600000000000004, 1.05400000000000005, 1.01000000000000001, 1.0149999999999999, 35, 50, 11, 17, 4.5, 5.20000000000000018, 'Altstadt brewpubs: Zum Uerige, Im FÃ¼chschen, Schumacher, Zum SchlÃ¼ssel; other examples: Diebels Alt, SchlÃ¶sser Alt, Frankenheim Alt');
INSERT INTO "BjcpStyle" VALUES ('beer', 8, 'English Pale Ale', '8A', 'Standard/Ordinary Bitter', 'The best examples have some malt aroma, often (but not always) with a caramel quality.  Mild to moderate fruitiness is common. Hop aroma can range from moderate to none (UK varieties typically, although US varieties may be used).  Generally no diacetyl, although very low levels are allowed.', 'Light yellow to light copper.  Good to brilliant clarity.  Low to moderate white to off-white head.  May have very little head due to low carbonation.', 'Medium to high bitterness.  Most have moderately low to moderately high fruity esters.  Moderate to low hop flavor (earthy, resiny, and/or floral UK varieties typically, although US varieties may be used).  Low to medium maltiness with a dry finish.  Caramel flavors are common but not required.  Balance is often decidedly bitter, although the bitterness should not completely overpower the malt flavor, esters and hop flavor.  Generally no diacetyl, although very low levels are allowed.', 'Light to medium-light body.  Carbonation low, although bottled and canned examples can have moderate carbonation.', 'Low gravity, low alcohol levels and low carbonation make this an easy-drinking beer.  Some examples can be more malt balanced, but this should not override the overall bitter impression.  Drinkability is a critical component of the style; emphasis is still on the bittering hop addition as opposed to the aggressive middle and late hopping seen in American ales.', 'The lightest of the bitters.  Also known as just "bitter."  Some modern variants are brewed exclusively with pale malt and are known as golden or summer bitters.  Most bottled or kegged versions of UK-produced bitters are higher-alcohol versions of their cask (draught) products produced specifically for export.  The IBU levels are often not adjusted, so the versions available in the US often do not directly correspond to their style subcategories in Britain.  This style guideline reflects the "real ale" version of the style, not the export formulations of commercial products.', 'Pale ale, amber, and/or crystal malts, may use a touch of black malt for color adjustment.  May use sugar adjuncts, corn or wheat.  English hops most typical, although American and European varieties are becoming more common (particularly in the paler examples).  Characterful English yeast.  Often medium sulfate water is used.', 1.03200000000000003, 1.04000000000000004, 1.0069999999999999, 1.0109999999999999, 25, 35, 4, 14, 3.20000000000000018, 3.79999999999999982, 'Fuller''s Chiswick Bitter, Adnams Bitter, Young''s Bitter, Greene King IPA, Oakham Jeffrey Hudson Bitter (JHB), Brains Bitter, Tetleyï¿½s Original Bitter, Brakspear Bitter, Boddington''s Pub Draught ');
INSERT INTO "BjcpStyle" VALUES ('beer', 8, 'English Pale Ale', '8B', 'Special/Best/Premium Bitter', 'The best examples have some malt aroma, often (but not always) with a caramel quality.  Mild to moderate fruitiness.  Hop aroma can range from moderate to none (UK varieties typically, although US varieties may be used).  Generally no diacetyl, although very low levels are allowed.', 'Medium gold to medium copper.  Good to brilliant clarity.  Low to moderate white to off-white head.  May have very little head due to low carbonation.', 'Medium to high bitterness.  Most have moderately low to moderately high fruity esters.  Moderate to low hop flavor (earthy, resiny, and/or floral UK varieties typically, although US varieties may be used).  Low to medium maltiness with a dry finish.  Caramel flavors are common but not required.  Balance is often decidedly bitter, although the bitterness should not completely overpower the malt flavor, esters and hop flavor.  Generally no diacetyl, although very low levels are allowed.', 'Medium-light to medium body. Carbonation low, although bottled and canned commercial examples can have moderate carbonation.', 'A flavorful, yet refreshing, session beer.  Some examples can be more malt balanced, but this should not override the overall bitter impression.  Drinkability is a critical component of the style; emphasis is still on the bittering hop addition as opposed to the aggressive middle and late hopping seen in American ales.', 'More evident malt flavor than in an ordinary bitter, this is a stronger, session-strength ale. Some modern variants are brewed exclusively with pale malt and are known as golden or summer bitters.  Most bottled or kegged versions of UK-produced bitters are higher-alcohol versions of their cask (draught) products produced specifically for export.  The IBU levels are often not adjusted, so the versions available in the US often do not directly correspond to their style subcategories in Britain.  This style guideline reflects the "real ale" version of the style, not the export formulations of commercial products.', 'Pale ale, amber, and/or crystal malts, may use a touch of black malt for color adjustment.  May use sugar adjuncts, corn or wheat.  English hops most typical, although American and European varieties are becoming more common (particularly in the paler examples).  Characterful English yeast.  Often medium sulfate water is used.', 1.04000000000000004, 1.04800000000000004, 1.00800000000000001, 1.01200000000000001, 25, 40, 5, 16, 3.79999999999999982, 4.59999999999999964, 'Fuller''s London Pride, Coniston Bluebird Bitter, Timothy Taylor Landlord, Adnams SSB, Young''s Special, Shepherd Neame Masterbrew Bitter, Greene King Ruddles County Bitter, RCH Pitchfork Rebellious Bitter, Brains SA, Black Sheep Best Bitter, Goose Island Honkers Ale, Rogue Younger''s Special Bitter');
INSERT INTO "BjcpStyle" VALUES ('beer', 8, 'English Pale Ale', '8C', 'Extra Special/Strong Bitter (English Pale Ale)', 'Hop aroma moderately-high to moderately-low, and can use any variety of hops although UK hops are most traditional.  Medium to medium-high malt aroma, often with a low to moderately strong caramel component (although this character will be more subtle in paler versions). Medium-low to medium-high fruity esters.  Generally no diacetyl, although very low levels are allowed.   May have light, secondary notes of sulfur and/or alcohol in some examples (optional).', 'Golden to deep copper.  Good to brilliant clarity.  Low to moderate white to off-white head.  A low head is acceptable when carbonation is also low.', 'Medium-high to medium bitterness with supporting malt flavors evident.  Normally has a moderately low to somewhat strong caramelly malt sweetness.  Hop flavor moderate to moderately high (any variety, although earthy, resiny, and/or floral UK hops are most traditional).  Hop bitterness and flavor should be noticeable, but should not totally dominate malt flavors.  May have low levels of secondary malt flavors (e.g., nutty, biscuity) adding complexity.  Moderately-low to high fruity esters.  Optionally may have low amounts of alcohol, and up to a moderate minerally/sulfury flavor.  Medium-dry to dry finish (particularly if sulfate water is used).  Generally no diacetyl, although very low levels are allowed.', 'Medium-light to medium-full body.  Low to moderate carbonation, although bottled commercial versions will be higher.  Stronger versions may have a slight alcohol warmth but this character should not be too high.', 'An average-strength to moderately-strong English ale. The balance may be fairly even between malt and hops to somewhat bitter.  Drinkability is a critical component of the style; emphasis is still on the bittering hop addition as opposed to the aggressive middle and late hopping seen in American ales.  A rather broad style that allows for considerable interpretation by the brewer.', 'More evident malt and hop flavors than in a special or best bitter.  Stronger versions may overlap somewhat with old ales, although strong bitters will tend to be paler and more bitter.  Fuller''s ESB is a unique beer with a very large, complex malt profile not found in other examples; most strong bitters are fruitier and hoppier. Judges should not judge all beers in this style as if they were Fuller''s ESB clones.  Some modern English variants are brewed exclusively with pale malt and are known as golden or summer bitters. Most bottled or kegged versions of UK-produced bitters are higher-alcohol versions of their cask (draught) products produced specifically for export.  The IBU levels are often not adjusted, so the versions available in the US often do not directly correspond to their style subcategories in Britain.  English pale ales are generally considered a premium, export-strength pale, bitter beer that roughly approximates a strong bitter, although reformulated for bottling (including containing higher carbonation).', 'Pale ale, amber, and/or crystal malts, may use a touch of black malt for color adjustment.  May use sugar adjuncts, corn or wheat.  English hops most typical, although American and European varieties are becoming more common (particularly in the paler examples).  Characterful English yeast.  "Burton" versions use medium to high sulfate water.', 1.04800000000000004, 1.06000000000000005, 1.01000000000000001, 1.01600000000000001, 30, 50, 6, 18, 4.59999999999999964, 6.20000000000000018, 'Examples: Fullers ESB, Adnams Broadside, Shepherd Neame Bishop''s Finger, Young''s Ram Rod, Samuel Smith''s Old Brewery Pale Ale, Bass Ale, Whitbread Pale Ale, Shepherd Neame Spitfire, Marston''s Pedigree, Black Sheep Ale, Vintage Henley, Mordue Workie Ticket, Morland Old Speckled Hen, Greene King Abbot Ale, Bateman''s  XXXB, Gale''s Hordean Special Bitter (HSB), Ushers 1824 Particular Ale, Hopback Summer Lightning, Great Lakes Moondog Ale, Shipyard Old Thumper, Alaskan ESB, Geary''s Pale Ale, Cooperstown Old Slugger, Anderson Valley Boont ESB, Avery 14''er ESB, Redhook ESB');
INSERT INTO "BjcpStyle" VALUES ('beer', 9, 'Scottish and Irish Ale', '9A', 'Scottish Light 60/-', 'Low to medium malty sweetness, sometimes accentuated by low to moderate kettle caramelization.  Some examples have a low hop aroma, light fruitiness, low diacetyl, and/or a low to moderate peaty aroma (all are optional).  The peaty aroma is sometimes perceived as earthy, smoky or very lightly roasted.', 'Deep amber to dark copper. Usually very clear due to long, cool fermentations.  Low to moderate, creamy off-white to light tan-colored head.', 'Malt is the primary flavor, but isn''t overly strong.  The initial malty sweetness is usually accentuated by a low to moderate kettle caramelization, and is sometimes accompanied by a low diacetyl component.  Fruity esters may be moderate to none.  Hop bitterness is low to moderate, but the balance will always be towards the malt (although not always by much).  Hop flavor is low to none.  A low to moderate peaty character is optional, and may be perceived as earthy or smoky. Generally has a grainy, dry finish due to small amounts of unmalted roasted barley.', 'Medium-low to medium body. Low to moderate carbonation.  Sometimes a bit creamy, but often quite dry due to use of roasted barley.', 'Cleanly malty with a drying finish, perhaps a few esters, and on occasion a faint bit of peaty earthiness (smoke).  Most beers finish fairly dry considering their relatively sweet palate, and as such have a different balance than strong Scotch ales.', 'The malt-hop balance is slightly to moderately tilted towards the malt side. Any caramelization comes from kettle caramelization and not caramel malt (and is sometimes confused with diacetyl).  Although unusual, any smoked character is yeast- or water-derived and not from the use of peat-smoked malts.  Use of peat-smoked malt to replicate the peaty character should be restrained; overly smoky beers should be entered in the Other Smoked Beer category (22B) rather than here.', 'Scottish or English pale base malt. Small amounts of roasted barley add color and flavor, and lend a dry, slightly roasty finish. English hops. Clean, relatively un-attenuative ale yeast. Some commercial brewers add small amounts of crystal, amber, or wheat malts, and adjuncts such as sugar.  The optional peaty, earthy and/or smoky character comes from the traditional yeast and from the local malt and water rather than using smoked malts.', 1.03000000000000003, 1.03499999999999992, 1.01000000000000001, 1.0129999999999999, 10, 20, 9, 17, 2.5, 3.20000000000000018, 'Belhaven 60/-, McEwan''s 60/-, Maclay 60/- Light (all are cask-only products not exported to the US)');
INSERT INTO "BjcpStyle" VALUES ('beer', 9, 'Scottish and Irish Ale', '9B', 'Scottish Heavy 70/-', 'Low to medium malty sweetness, sometimes accentuated by low to moderate kettle caramelization.  Some examples have a low hop aroma, light fruitiness, low diacetyl, and/or a low to moderate peaty aroma (all are optional).  The peaty aroma is sometimes perceived as earthy, smoky or very lightly roasted.', 'Deep amber to dark copper. Usually very clear due to long, cool fermentations.  Low to moderate, creamy off-white to light tan-colored head.', 'Malt is the primary flavor, but isn''t overly strong.  The initial malty sweetness is usually accentuated by a low to moderate kettle caramelization, and is sometimes accompanied by a low diacetyl component.  Fruity esters may be moderate to none.  Hop bitterness is low to moderate, but the balance will always be towards the malt (although not always by much).  Hop flavor is low to none.  A low to moderate peaty character is optional, and may be perceived as earthy or smoky. Generally has a grainy, dry finish due to small amounts of unmalted roasted barley.', 'Medium-low to medium body. Low to moderate carbonation.  Sometimes a bit creamy, but often quite dry due to use of roasted barley.', 'Cleanly malty with a drying finish, perhaps a few esters, and on occasion a faint bit of peaty earthiness (smoke).  Most beers finish fairly dry considering their relatively sweet palate, and as such have a different balance than strong Scotch ales.', 'The malt-hop balance is slightly to moderately tilted towards the malt side. Any caramelization comes from kettle caramelization and not caramel malt (and is sometimes confused with diacetyl).  Although unusual, any smoked character is yeast- or water-derived and not from the use of peat-smoked malts.  Use of peat-smoked malt to replicate the peaty character should be restrained; overly smoky beers should be entered in the Other Smoked Beer category (22B) rather than here.', 'Scottish or English pale base malt. Small amounts of roasted barley add color and flavor, and lend a dry, slightly roasty finish. English hops. Clean, relatively un-attenuative ale yeast. Some commercial brewers add small amounts of crystal, amber, or wheat malts, and adjuncts such as sugar.  The optional peaty, earthy and/or smoky character comes from the traditional yeast and from the local malt and water rather than using smoked malts.', 1.03499999999999992, 1.04000000000000004, 1.01000000000000001, 1.0149999999999999, 10, 25, 9, 17, 3.20000000000000018, 3.89999999999999991, 'Caledonian 70/- (Caledonian Amber Ale in the US), Belhaven 70/-, Orkney Raven Ale, Maclay 70/-, Tennents Special, Broughton Greenmantle Ale');
INSERT INTO "BjcpStyle" VALUES ('beer', 9, 'Scottish and Irish Ale', '9C', 'Scottish Export 80/-', 'Low to medium malty sweetness, sometimes accentuated by low to moderate kettle caramelization.  Some examples have a low hop aroma, light fruitiness, low diacetyl, and/or a low to moderate peaty aroma (all are optional).  The peaty aroma is sometimes perceived as earthy, smoky or very lightly roasted.', 'Deep amber to dark copper. Usually very clear due to long, cool fermentations.  Low to moderate, creamy off-white to light tan-colored head.', 'Malt is the primary flavor, but isn''t overly strong.  The initial malty sweetness is usually accentuated by a low to moderate kettle caramelization, and is sometimes accompanied by a low diacetyl component.  Fruity esters may be moderate to none.  Hop bitterness is low to moderate, but the balance will always be towards the malt (although not always by much).  Hop flavor is low to none.  A low to moderate peaty character is optional, and may be perceived as earthy or smoky. Generally has a grainy, dry finish due to small amounts of unmalted roasted barley.  ', 'Medium-low to medium body. Low to moderate carbonation.  Sometimes a bit creamy, but often quite dry due to use of roasted barley.', 'Cleanly malty with a drying finish, perhaps a few esters, and on occasion a faint bit of peaty earthiness (smoke).  Most beers finish fairly dry considering their relatively sweet palate, and as such have a different balance than strong Scotch ales.', 'The malt-hop balance is slightly to moderately tilted towards the malt side. Any caramelization comes from kettle caramelization and not caramel malt (and is sometimes confused with diacetyl).  Although unusual, any smoked character is yeast- or water-derived and not from the use of peat-smoked malts.  Use of peat-smoked malt to replicate the peaty character should be restrained; overly smoky beers should be entered in the Other Smoked Beer category (22B) rather than here.  ', 'Scottish or English pale base malt. Small amounts of roasted barley add color and flavor, and lend a dry, slightly roasty finish. English hops. Clean, relatively un-attenuative ale yeast. Some commercial brewers add small amounts of crystal, amber, or wheat malts, and adjuncts such as sugar.  The optional peaty, earthy and/or smoky character comes from the traditional yeast and from the local malt and water rather than using smoked malts.', 1.04000000000000004, 1.05400000000000005, 1.01000000000000001, 1.01600000000000001, 15, 30, 9, 17, 3.89999999999999991, 5, 'Orkney Dark Island, Caledonian 80/- Export Ale, Belhaven 80/- (Belhaven Scottish Ale in the US), Southampton 80 Shilling, Broughton Exciseman''s 80/-, Belhaven St. Andrews Ale, McEwan''s Export (IPA), Inveralmond Lia Fail, Broughton Merlin''s Ale, Arran Dark');
INSERT INTO "BjcpStyle" VALUES ('beer', 9, 'Scottish and Irish Ale', '9D', 'Irish Red Ale', 'Low to moderate malt aroma, generally caramel-like but occasionally toasty or toffee-like in nature.  May have a light buttery character (although this is not required).  Hop aroma is low to none (usually not present).  Quite clean.', 'Amber to deep reddish copper color (most examples have a deep reddish hue).  Clear.  Low off-white to tan colored head.', 'Moderate caramel malt flavor and sweetness, occasionally with a buttered toast or toffee-like quality.  Finishes with a light taste of roasted grain, which lends a characteristic dryness to the finish.  Generally no flavor hops, although some examples may have a light English hop flavor.  Medium-low hop bitterness, although light use of roasted grains may increase the perception of bitterness to the medium range.  Medium-dry to dry finish.  Clean and smooth (lager versions can be very smooth).  No esters.', 'Medium-light to medium body, although examples containing low levels of diacetyl may have a slightly slick mouthfeel.  Moderate carbonation.  Smooth.  Moderately attenuated (more so than Scottish ales).  May have a slight alcohol warmth in stronger versions.', 'An easy-drinking pint.  Malt-focused with an initial sweetness and a roasted dryness in the finish.', 'Sometimes brewed as a lager (if so, generally will not exhibit a diacetyl character).  When served too cold, the roasted character and bitterness may seem more elevated.', 'May contain some adjuncts (corn, rice, or sugar), although excessive adjunct use will harm the character of the beer.  Generally has a bit of roasted barley to provide reddish color and dry roasted finish.  UK/Irish malts, hops, yeast.', 1.04400000000000004, 1.06000000000000005, 1.01000000000000001, 1.01400000000000001, 17, 28, 9, 18, 4, 6, 'Three Floyds Brian Boru Old Irish Ale, Great Lakes Conway''s Irish Ale (a bit strong at 6.5%), Kilkenny Irish Beer, O''Hara''s Irish Red Ale, Smithwick''s Irish Ale, Beamish Red Ale, Caffrey''s Irish Ale, Goose Island Kilgubbin Red Ale, Murphy''s Irish Red (lager), Boulevard Irish Ale, Harpoon Hibernian Ale');
INSERT INTO "BjcpStyle" VALUES ('beer', 9, 'Scottish and Irish Ale', '9E', 'Strong Scotch Ale', 'Deeply malty, with caramel often apparent. Peaty, earthy and/or smoky secondary aromas may also be present, adding complexity.  Caramelization often is mistaken for diacetyl, which should be low to none.  Low to moderate esters and alcohol are often present in stronger versions.  Hops are very low to none.', 'Light copper to dark brown color, often with deep ruby highlights.  Clear.  Usually has a large tan head, which may not persist in stronger versions.  Legs may be evident in stronger versions.', 'Richly malty with kettle caramelization often apparent (particularly in stronger versions).  Hints of roasted malt or smoky flavor may be present, as may some nutty character, all of which may last into the finish.  Hop flavors and bitterness are low to medium-low, so malt impression should dominate.  Diacetyl is low to none, although caramelization may sometimes be mistaken for it.  Low to moderate esters and alcohol are usually present.  Esters may suggest plums, raisins or dried fruit.  The palate is usually full and sweet, but the finish may be sweet to medium-dry (from light use of roasted barley).', 'Medium-full to full-bodied, with some versions (but not all) having a thick, chewy viscosity. A smooth, alcoholic warmth is usually present and is quite welcome since it balances the malty sweetness.  Moderate carbonation.', 'Rich, malty and usually sweet, which can be suggestive of a dessert. Complex secondary malt flavors prevent a one-dimensional impression.  Strength and maltiness can vary.', 'Also known as a "wee heavy."  Fermented at cooler temperatures than most ales, and with lower hopping rates, resulting in clean, intense malt flavors.  Well suited to the region of origin, with abundant malt and cool fermentation and aging temperature.  Hops, which are not native to Scotland and formerly expensive to import, were kept to a minimum.', 'Well-modified pale malt, with up to 3% roasted barley.  May use some crystal malt for color adjustment; sweetness usually comes not from crystal malts rather from low hopping, high mash temperatures, and kettle caramelization. A small proportion of smoked malt may add depth, though a peaty character (sometimes perceived as earthy or smoky) may also originate from the yeast and native water. Hop presence is minimal, although English varieties are most authentic. Fairly soft water is typical.', 1.07000000000000006, 1.12999999999999989, 1.01800000000000002, 1.05600000000000005, 17, 35, 14, 25, 6.5, 10, 'Traquair House Ale, Belhaven Wee Heavy, McEwan''s Scotch Ale, Founders Dirty Bastard, MacAndrew''s Scotch Ale, AleSmith Wee Heavy, Orkney Skull Splitter, Inveralmond Black Friar, Broughton Old Jock, Gordon Highland Scotch Ale, Dragonmead Under the Kilt ');


--
-- Data for Name: BjcpStyleUrlFriendlyName; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('10A', 'american-pale-ale');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('10B', 'american-amber-ale');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('10C', 'american-brown-ale');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('11A', 'mild');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('11B', 'southern-english-brown');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('11C', 'northern-english-brown-ale');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('12A', 'brown-porter');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('12B', 'robust-porter');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('12C', 'baltic-porter');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('13A', 'dry-stout');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('13B', 'sweet-stout');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('13C', 'oatmeal-stout');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('13D', 'foreign-extra-stout');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('13E', 'american-stout');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('13F', 'russian-imperial-stout');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('14A', 'english-ipa');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('14B', 'american-ipa');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('14C', 'imperial-ipa');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('15A', 'weizen-weissbier');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('15B', 'dunkelweizen');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('15C', 'weizenbock');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('15D', 'roggenbier-german-rye-beer');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('16A', 'witbier');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('16B', 'belgian-pale-ale');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('16C', 'saison');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('16D', 'bière-de-garde');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('17A', 'berliner-weisse');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('17B', 'flanders-red-ale');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('17C', 'flanders-brown-ale-oud-bruin');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('17D', 'straight-unblended-lambic');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('17E', 'gueuze');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('17F', 'fruit-lambic');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('18A', 'belgian-blond-ale');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('18B', 'belgian-dubbel');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('18C', 'belgian-tripel');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('18D', 'belgian-golden-strong-ale');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('18E', 'belgian-dark-strong-ale');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('19A', 'old-ale');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('19B', 'english-barleywine');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('19C', 'american-barleywine');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('1A', 'lite-american-lager');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('1B', 'standard-american-lager');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('1C', 'premium-american-lager');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('1D', 'munich-helles');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('1E', 'dortmunder-export');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('22A', 'classic-rauchbier');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('27A', 'common-cider');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('27B', 'english-cider');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('27C', 'french-cider');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('27D', 'common-perry');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('27E', 'traditional-perry');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('28A', 'new-england-cider');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('28B', 'fruit-cider');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('28C', 'applewine');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('28D', 'other-specialty-cider-perry');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('2A', 'german-pilsner-pils');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('2B', 'bohemian-pilsener');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('2C', 'classic-american-pilsner');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('3A', 'vienna-lager');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('3B', 'oktoberfest-mã¤rzen');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('4A', 'dark-american-lager');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('4B', 'munich-dunkel');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('4C', 'schwarzbier-black-beer');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('5A', 'maibock-helles-bock');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('5B', 'traditional-bock');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('5C', 'doppelbock');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('5D', 'eisbock');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('6A', 'cream-ale');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('6B', 'blonde-ale');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('6C', 'kölsch');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('6D', 'american-wheat-or-rye-beer');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('7A', 'northern-german-altbier');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('7B', 'california-common-beer');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('7C', 'düsseldorf-altbier');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('8A', 'standard-ordinary-bitter');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('8B', 'special-best-premium-bitter');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('8C', 'extra-special-strong-bitter-english-pale-ale');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('9A', 'scottish-light-60');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('9B', 'scottish-heavy-70');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('9C', 'scottish-export-80');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('9D', 'irish-red-ale');
INSERT INTO "BjcpStyleUrlFriendlyName" VALUES ('9E', 'strong-scotch-ale');


--
-- Data for Name: BrewSession; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: BrewSessionComment; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: Content; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: ContentType; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "ContentType" VALUES (10, 'Web');
INSERT INTO "ContentType" VALUES (20, 'Email');


--
-- Data for Name: Exceptions; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: Fermentable; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "Fermentable" VALUES (1, NULL, 'UK Pilsner 2-Row', NULL, 36, 1, 10, true, false, '2012-04-26 17:24:08.91', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (2, NULL, 'Malted Oats - US', 'x', 37, 1, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (3, NULL, '2-Row - US', 'x', 37, 1, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (4, NULL, '6-Row - US', 'x', 35, 2, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (5, NULL, 'Pilsner - BE', 'x', 36, 2, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (6, NULL, 'German Pilsner 2-Row', NULL, 37, 2, 10, true, false, '2012-04-26 17:24:08.91', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (7, NULL, 'Lager Malt - UK', 'x', 38, 2, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (8, NULL, 'Wheat - BE', 'x', 37, 2, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (9, NULL, 'German Wheat', NULL, 39, 2, 10, true, false, '2012-04-26 17:24:08.91', NULL, NULL);
INSERT INTO "Fermentable" VALUES (10, NULL, 'White Wheat - US', 'x', 40, 2, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (11, NULL, 'Carapils - DE', 'x', 33, 2, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (12, NULL, 'Dextrine Malt - UK', 'x', 33, 2, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (13, NULL, 'Acid Malt', NULL, 27, 3, 10, true, false, '2012-04-26 17:24:08.91', NULL, NULL);
INSERT INTO "Fermentable" VALUES (14, NULL, 'Peated Malt - UK', 'x', 34, 3, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (15, NULL, 'Maris Otter Pale - UK', 'x', 38, 3, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (16, NULL, 'English Mild', NULL, 37, 4, 10, true, false, '2012-04-26 17:24:08.91', NULL, NULL);
INSERT INTO "Fermentable" VALUES (17, NULL, 'Vienna - US', 'x', 36, 4, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (18, NULL, 'Toasted Malt', NULL, 29, 5, 10, true, false, '2012-04-26 17:24:08.91', NULL, NULL);
INSERT INTO "Fermentable" VALUES (19, NULL, 'Dark Wheat - DE', 'x', 39, 9, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (20, NULL, 'Munich - UK', 'x', 37, 9, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (21, NULL, 'Smoked Malt - US', 'x', 37, 9, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (22, NULL, 'Caramel/Crystal 10 - US', 'x', 35, 10, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (23, NULL, 'Carastan 15 - UK', 'x', 35, 15, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Grains');
INSERT INTO "Fermentable" VALUES (24, NULL, 'Munich - Light 10L - US', 'x', 35, 10, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (25, NULL, 'Caramel/Crystal 20 - US', 'x', 35, 20, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (26, NULL, 'Munich - Dark 20L - US', 'x', 35, 20, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (27, NULL, 'CaraRed - DE', 'x', 35, 20, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (28, NULL, 'Melanoidin Malt - US', 'x', 37, 20, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (29, NULL, 'Amber - UK', 'x', 32, 27, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Grains');
INSERT INTO "Fermentable" VALUES (30, NULL, 'CaraVienna - BE', 'x', 34, 22, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (31, NULL, 'Biscuit Malt - BE', 'x', 36, 23, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (32, NULL, 'Brumalt - BE', 'x', 33, 23, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (33, NULL, 'Gambrinus Honey Malt', NULL, 37, 25, 10, true, false, '2012-04-26 17:24:08.91', NULL, NULL);
INSERT INTO "Fermentable" VALUES (34, NULL, 'Belgian Aromatic - BE', 'x', 37, 32, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (35, NULL, 'Victory Malt - US', 'x', 34, 28, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (36, NULL, 'Caramel/Crystal 30 - US', 'x', 35, 30, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (37, NULL, 'Carastan 35 - UK', 'x', 35, 35, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Grains');
INSERT INTO "Fermentable" VALUES (38, NULL, 'Caramel/Crystal 40 - US', 'x', 35, 40, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (39, NULL, 'Caramel Wheat Malt - DE', 'x', 35, 46, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (40, NULL, 'Special Roast - US', 'x', 33, 50, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Roasted Malts');
INSERT INTO "Fermentable" VALUES (41, NULL, 'CaraMunich - BE', 'x', 34, 56, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (42, NULL, 'Caramel/Crystal 60 - US', 'x', 36, 60, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (43, NULL, 'Brown Malt - UK', 'x', 33, 65, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Grains');
INSERT INTO "Fermentable" VALUES (44, NULL, 'Caramel/Crystal 80 - US', 'x', 35, 80, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (45, NULL, 'Caramel/Crystal 90 - US', 'x', 35, 90, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (46, NULL, 'Caramel/Crystal 120 - US', 'x', 35, 120, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (47, NULL, 'CaraAroma - DE', 'x', 35, 130, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (48, NULL, 'Caramel/Crystal 150 - US', 'x', 35, 150, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (49, NULL, 'Special B', NULL, 30, 180, 10, true, false, '2012-04-26 17:24:08.91', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (50, NULL, 'Chocolate Rye Malt - DE', 'x', 34, 250, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Roasted Malts');
INSERT INTO "Fermentable" VALUES (51, NULL, 'Roasted Barley - US', 'x', 25, 300, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Roasted Malts');
INSERT INTO "Fermentable" VALUES (52, NULL, 'Carafa I - DE', 'x', 32, 337, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (53, NULL, 'Chocolate Malt - US', 'x', 34, 350, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Roasted Malts');
INSERT INTO "Fermentable" VALUES (54, NULL, 'Chocolate Wheat Malt - DE', 'x', 33, 400, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Roasted Malts');
INSERT INTO "Fermentable" VALUES (55, NULL, 'Carafa II - DE', 'x', 32, 412, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (56, NULL, 'Black Patent Malt - UK', 'x', 25, 500, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Roasted Malts');
INSERT INTO "Fermentable" VALUES (57, NULL, 'Black Barley - US', 'x', 25, 500, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Roasted Malts');
INSERT INTO "Fermentable" VALUES (58, NULL, 'Carafa III - DE', 'x', 32, 525, 10, true, true, '2012-04-26 17:24:08.91', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (69, NULL, 'Dry Malt Extract - Extra Light - US', 'x', 44, 3, 20, true, true, '2012-07-18 22:31:23.283', NULL, 'Dry Malt Extracts');
INSERT INTO "Fermentable" VALUES (71, NULL, 'Dry Malt Extract - Light - US', 'x', 44, 8, 20, true, true, '2012-07-18 22:34:43.79', NULL, 'Dry Malt Extracts');
INSERT INTO "Fermentable" VALUES (72, NULL, 'Dry Malt Extract - Amber - US', 'x', 44, 13, 20, true, false, '2012-07-18 22:35:10.04', NULL, 'Dry Malt Extracts');
INSERT INTO "Fermentable" VALUES (73, NULL, 'Dry Malt Extract - Dark - US', 'x', 44, 18, 20, true, true, '2012-07-18 22:35:53.14', NULL, 'Dry Malt Extracts');
INSERT INTO "Fermentable" VALUES (74, NULL, 'Pale Liquid Malt Extract', NULL, 36, 8, 20, true, false, '2012-07-18 22:36:44.397', NULL, 'Liquid Malt Extracts');
INSERT INTO "Fermentable" VALUES (76, NULL, 'Amber Liquid Malt Extract', NULL, 36, 13, 20, true, false, '2012-07-18 22:37:10.2', NULL, 'Liquid Malt Extracts');
INSERT INTO "Fermentable" VALUES (77, NULL, 'Liquid Malt Extract - Dark - US', 'x', 36, 18, 20, true, true, '2012-07-18 22:37:54.643', NULL, 'Liquid Malt Extracts');
INSERT INTO "Fermentable" VALUES (78, NULL, 'Flaked Barley - US', 'x', 32, 2, 10, true, true, '2012-07-18 22:40:42.703', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (79, NULL, 'Raw Barley', NULL, 28, 2, 10, true, false, '2012-07-18 22:41:03.11', NULL, NULL);
INSERT INTO "Fermentable" VALUES (80, NULL, 'Torrefied Barley - US', 'x', 36, 2, 10, true, true, '2012-07-18 22:41:43.853', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (82, NULL, 'Dark Brown Sugar - US', 'x', 46, 50, 40, true, true, '2012-07-18 22:48:10.11', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (84, NULL, 'Belgian Amber Candi Sugar - BE', 'x', 36, 75, 40, true, true, '2012-07-18 22:49:30.91', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (85, NULL, 'Belgian Clear Candi Sugar - BE', 'x', 36, 1, 40, true, true, '2012-07-18 22:49:53.143', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (86, NULL, 'Belgian Dark Candi Sugar - BE', 'x', 36, 275, 40, true, true, '2012-07-18 22:50:22.707', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (87, NULL, 'Corn Sugar (Dextrose) - US', 'x', 46, 0, 40, true, true, '2012-07-18 22:51:26.46', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (88, NULL, 'Corn Syrup - US', 'x', 36, 1, 40, true, true, '2012-07-18 22:51:45.113', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (89, NULL, 'Flaked Corn - US', 'x', 37, 1, 10, true, true, '2012-07-18 22:52:18.8', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (90, NULL, 'Honey - US', 'x', 35, 1, 40, true, true, '2012-07-18 22:52:50.21', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (91, NULL, 'Maple Syrup - US', 'x', 30, 35, 40, true, true, '2012-07-18 22:53:09.41', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (92, NULL, 'Molasses - US', 'x', 36, 80, 40, true, true, '2012-07-18 22:53:38.143', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (93, NULL, 'Rice Liquid Extract', NULL, 32, 7, 20, true, false, '2012-07-18 22:54:43.503', NULL, 'Liquid Malt Extracts');
INSERT INTO "Fermentable" VALUES (94, NULL, 'Flaked Rice - US', 'x', 32, 1, 10, true, true, '2012-07-18 22:55:05.5', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (95, NULL, 'Flaked Rye - US', 'x', 36, 2, 10, true, true, '2012-07-18 22:55:24.227', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (96, NULL, 'Flaked Wheat - US', 'x', 35, 2, 10, true, true, '2012-07-18 22:56:00.013', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (147, NULL, 'Extra Pale Liquid Malt Extract', NULL, 37, 2, 20, true, false, '2013-02-01 22:23:50.797', NULL, 'Liquid Malt Extracts');
INSERT INTO "Fermentable" VALUES (148, NULL, 'Wheat Liquid Extract', NULL, 35, 3, 20, true, false, '2013-02-01 22:29:15.167', NULL, 'Liquid Malt Extracts');
INSERT INTO "Fermentable" VALUES (149, NULL, 'Pilsner - US', 'x', 34, 1, 20, true, true, '2013-02-01 22:39:09.973', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (150, NULL, 'Wheat - US', 'x', 39, 1, 10, true, true, '2013-02-01 22:42:24.897', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (151, NULL, 'Rye - US', 'x', 37, 3, 10, true, true, '2013-02-01 22:44:58.41', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (152, NULL, 'Flaked Oats - US', 'x', 37, 1, 10, true, true, '2013-02-01 23:09:30.36', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (153, NULL, 'Table Sugar - Sucrose - US', 'x', 46, 0, 40, true, true, '2013-02-01 23:14:50.64', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (473, NULL, 'Abbey Malt - DE', 'x', 33, 17, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Grains');
INSERT INTO "Fermentable" VALUES (474, NULL, 'Acidulated Malt - DE
', 'x', 27, 3, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (475, NULL, 'Aromatic Malt - UK
', 'x', 35, 20, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (476, NULL, 'Aromatic Malt - US', 'x', 35, 20, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (477, NULL, 'Ashbourne Mild - US', 'x', 30, 5, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Grains');
INSERT INTO "Fermentable" VALUES (478, NULL, 'Belgian Amber Candi Syrup - BE
', 'x', 32, 40, 20, true, true, '2014-01-20 21:19:06.69', NULL, 'Liquid Malt Extracts');
INSERT INTO "Fermentable" VALUES (479, NULL, 'Belgian Clear Candi Syrup - BE
', 'x', 32, 1, 20, true, true, '2014-01-20 21:19:06.69', NULL, 'Liquid Malt Extracts');
INSERT INTO "Fermentable" VALUES (480, NULL, 'Belgian D2 Candi Syrup - BE
', 'x', 32, 160, 20, true, true, '2014-01-20 21:19:06.69', NULL, 'Liquid Malt Extracts');
INSERT INTO "Fermentable" VALUES (481, NULL, 'Belgian Dark Candi Syrup - BE
', 'x', 32, 80, 20, true, true, '2014-01-20 21:19:06.69', NULL, 'Liquid Malt Extracts');
INSERT INTO "Fermentable" VALUES (482, NULL, 'Black Malt - UK', 'x', 28, 500, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Roasted Malts');
INSERT INTO "Fermentable" VALUES (483, NULL, 'Black Malt - US', 'x', 28, 500, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Roasted Malts');
INSERT INTO "Fermentable" VALUES (484, NULL, 'Blackprinz - US', 'x', 36, 500, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Roasted Malts');
INSERT INTO "Fermentable" VALUES (485, NULL, 'Bohemian Pilsner - DE', 'x', 38, 1, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (486, NULL, 'Bonlander Munich - US', 'x', 36, 10, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (487, NULL, 'Brown Rice Syrup
 - US', 'x', 44, 2, 20, true, true, '2014-01-20 21:19:06.69', NULL, 'Liquid Malt Extracts');
INSERT INTO "Fermentable" VALUES (488, NULL, 'Cane Sugar
 - US', 'x', 46, 1, 40, true, true, '2014-01-20 21:19:06.69', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (489, NULL, 'Cara 20L - BE', 'x', 34, 20, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (490, NULL, 'Cara 45L - BE', 'x', 34, 45, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (491, NULL, 'CaraAmber - DE', 'x', 34, 27, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (492, NULL, 'CaraBelge - DE', 'x', 33, 13, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (493, NULL, 'CaraBohemian - DE', 'x', 33, 75, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (494, NULL, 'CaraBrown - US', 'x', 34, 55, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Grains');
INSERT INTO "Fermentable" VALUES (495, NULL, 'CaraCrystal Wheat Malt - US', 'x', 34, 55, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Grains');
INSERT INTO "Fermentable" VALUES (496, NULL, 'Caramel Pils - DE', 'x', 34, 8, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (497, NULL, 'Caramel/Crystal 15 - US', 'x', 35, 15, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (498, NULL, 'Caramel/Crystal 75 - US', 'x', 35, 75, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (499, NULL, 'Dry Malt Extract - Amber
', 'x', 42, 10, 20, true, true, '2014-01-20 21:19:06.69', NULL, 'Dry Malt Extracts');
INSERT INTO "Fermentable" VALUES (500, NULL, 'Cara Malt - UK', 'x', 35, 17, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (501, NULL, 'CaraMunich I - DE', 'x', 34, 39, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (502, NULL, 'CaraMunich II - DE', 'x', 34, 46, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (503, NULL, 'CaraMunich III - DE', 'x', 34, 57, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (504, NULL, 'Caramel Pils - BE', 'x', 35, 2, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (505, NULL, 'Carapils - Dextrine Malt - US', 'x', 33, 1, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (506, NULL, 'Chocolate - BE', 'x', 30, 340, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Roasted Malts');
INSERT INTO "Fermentable" VALUES (507, NULL, 'Chocolate - UK', 'x', 34, 425, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Roasted Malts');
INSERT INTO "Fermentable" VALUES (508, NULL, 'Coffee Malt - UK', 'x', 36, 150, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Roasted Malts');
INSERT INTO "Fermentable" VALUES (509, NULL, 'Crystal 120L - CA', 'x', 33, 120, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (510, NULL, 'Crystal 140L - UK', 'x', 33, 140, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (511, NULL, 'Crystal 15L - CA', 'x', 34, 15, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (512, NULL, 'Crystal 15L - UK', 'x', 34, 15, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (513, NULL, 'Crystal 30L - UK', 'x', 34, 30, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (514, NULL, 'Crystal 40L - CA', 'x', 34, 40, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (515, NULL, 'Crystal 45L - UK', 'x', 34, 45, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (516, NULL, 'Crystal 50L - UK', 'x', 34, 50, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (517, NULL, 'Crystal 60L - CA', 'x', 34, 60, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (518, NULL, 'Crystal 60L - UK', 'x', 34, 60, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (519, NULL, 'Crystal 70L - UK', 'x', 34, 70, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (520, NULL, 'Crystal 90L - UK', 'x', 33, 90, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (521, NULL, 'Crystal Rye - UK', 'x', 33, 90, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (522, NULL, 'Dark Chocolate - US', 'x', 29, 420, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Roasted Malts');
INSERT INTO "Fermentable" VALUES (523, NULL, 'Dark Crystal 80L - UK', 'x', 33, 80, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (524, NULL, 'Dark Munich - DE', 'x', 36, 10, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (525, NULL, 'De-Husked Caraf I - DE', 'x', 32, 340, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (526, NULL, 'De-Husked Caraf II - DE', 'x', 32, 418, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (527, NULL, 'De-Husked Caraf III - DE', 'x', 32, 470, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (528, NULL, 'Dry Malt Extract - Munich - US', 'x', 42, 8, 20, true, true, '2014-01-20 21:19:06.69', NULL, 'Dry Malt Extracts');
INSERT INTO "Fermentable" VALUES (529, NULL, 'Dry Malt Extract - Pilsen - US', 'x', 42, 2, 20, true, true, '2014-01-20 21:19:06.69', NULL, 'Dry Malt Extracts');
INSERT INTO "Fermentable" VALUES (530, NULL, 'Dry Malt Extract - Wheat - US', 'x', 42, 3, 20, true, true, '2014-01-20 21:19:06.69', NULL, 'Dry Malt Extracts');
INSERT INTO "Fermentable" VALUES (531, NULL, 'ESB Malt - CA', 'x', 36, 3, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Grains');
INSERT INTO "Fermentable" VALUES (532, NULL, 'Extra Dark Crystal 120L - UK', 'x', 33, 120, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (533, NULL, 'Extra Dark Crystal 160L - UK', 'x', 33, 160, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (534, NULL, 'Floor-Malted Bohemian Dark Pilsner - DE', 'x', 38, 6, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (535, NULL, 'Floor-Malted Bohemian Pilsner - DE', 'x', 38, 1, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (536, NULL, 'Floor-Malted Bohemian Wheat - DE', 'x', 38, 1, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (537, NULL, 'Golden Naked Oats - UK', 'x', 33, 10, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (538, NULL, 'Golden Promise - UK', 'x', 37, 3, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (539, NULL, 'Grits - US', 'x', 37, 1, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (540, NULL, 'Halcyon - UK', 'x', 36, 2, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (541, NULL, 'Honey - Buckwheat - US', 'x', 42, 2, 40, true, true, '2014-01-20 21:19:06.69', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (542, NULL, 'Honey Malt - CA', 'x', 37, 25, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Caramel Malts');
INSERT INTO "Fermentable" VALUES (543, NULL, 'Invert Sugar - US', 'x', 46, 1, 40, true, true, '2014-01-20 21:19:06.69', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (544, NULL, 'Kölsch - DE', 'x', 37, 2, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (545, NULL, 'Lactose - Milk Sugar - US', 'x', 41, 1, 40, true, true, '2014-01-20 21:19:06.69', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (546, NULL, 'Liquid Malt Extract - Amber - US', 'x', 35, 10, 20, true, true, '2014-01-20 21:19:06.69', NULL, 'Liquid Malt Extracts');
INSERT INTO "Fermentable" VALUES (547, NULL, 'Liquid Malt Extract - Extra Light - US', 'x', 37, 2, 20, true, true, '2014-01-20 21:19:06.69', NULL, 'Liquid Malt Extracts');
INSERT INTO "Fermentable" VALUES (548, NULL, 'Liquid Malt Extract - Light - US', 'x', 35, 4, 20, true, true, '2014-01-20 21:19:06.69', NULL, 'Liquid Malt Extracts');
INSERT INTO "Fermentable" VALUES (549, NULL, 'Liquid Malt Extract - Munich - US', 'x', 35, 8, 20, true, true, '2014-01-20 21:19:06.69', NULL, 'Liquid Malt Extracts');
INSERT INTO "Fermentable" VALUES (550, NULL, 'Liquid Malt Extract - Pilsen - US', 'x', 35, 2, 20, true, true, '2014-01-20 21:19:06.69', NULL, 'Liquid Malt Extracts');
INSERT INTO "Fermentable" VALUES (551, NULL, 'Liquid Malt Extract - Wheat - US', 'x', 35, 3, 20, true, true, '2014-01-20 21:19:06.69', NULL, 'Liquid Malt Extracts');
INSERT INTO "Fermentable" VALUES (552, NULL, 'Malted Naked Oats - UK', 'x', 33, 1, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (553, NULL, 'Maltodextrin - US', 'x', 39, 0, 40, true, true, '2014-01-20 21:19:06.69', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (554, NULL, 'Mild - UK', 'x', 37, 3, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (555, NULL, 'Molasses - US', 'x', 36, 80, 40, true, true, '2014-01-20 21:19:06.69', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (556, NULL, 'Munich - 60L - US', 'x', 33, 60, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (557, NULL, 'Munich Dark - CA', 'x', 34, 32, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (558, NULL, 'Munich Dark - DE', 'x', 37, 15, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (559, NULL, 'Munich Light - CA', 'x', 34, 10, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (560, NULL, 'Munich Light - DE', 'x', 37, 6, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (561, NULL, 'Oat Malt - UK', 'x', 28, 2, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (562, NULL, 'Optic - UK', 'x', 38, 2, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (563, NULL, 'Pale 2-Row - CA', 'x', 36, 1, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (564, NULL, 'Pale 2-Row - Toasted - US', 'x', 33, 30, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (565, NULL, 'Pale 2-Row - US', 'x', 37, 1, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (566, NULL, 'Pale 6-Row - US', 'x', 35, 1, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (567, NULL, 'Pale Ale - BE', 'x', 38, 3, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (568, NULL, 'Pale Ale - CA', 'x', 37, 3, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (569, NULL, 'Pale Ale - DE', 'x', 39, 2, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (570, NULL, 'Pale Ale - US', 'x', 37, 3, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (571, NULL, 'Pale Wheat - CA', 'x', 36, 2, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (572, NULL, 'Pale Wheat - DE', 'x', 36, 2, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (573, NULL, 'Pearl - UK', 'x', 37, 2, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (574, NULL, 'Pilsen - UK', 'x', 36, 1, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (575, NULL, 'Pilsner - DE', 'x', 38, 1, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Base Malts');
INSERT INTO "Fermentable" VALUES (576, NULL, 'Red Wheat - US', 'x', 38, 2, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (577, NULL, 'Rice Syrup Solids', 'x', 37, 1, 20, true, true, '2014-01-20 21:19:06.69', NULL, 'Dry Malt Extracts');
INSERT INTO "Fermentable" VALUES (578, NULL, 'Roasted Barley - BE', 'x', 30, 575, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Roasted Malts');
INSERT INTO "Fermentable" VALUES (579, NULL, 'Roasted Barley - UK', 'x', 29, 550, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Roasted Malts');
INSERT INTO "Fermentable" VALUES (580, NULL, 'Rolled Oats - US', 'x', 33, 2, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (581, NULL, 'Rye - DE', 'x', 38, 3, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (582, NULL, 'Smoked Malt - DE', 'x', 37, 3, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (583, NULL, 'Soft Candi Sugar - Blond - US', 'x', 38, 5, 40, true, true, '2014-01-20 21:19:06.69', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (584, NULL, 'Soft Candi Sugar - Brown - US', 'x', 38, 60, 40, true, true, '2014-01-20 21:19:06.69', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (585, NULL, 'Spelt Malt - DE', 'x', 37, 2, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (586, NULL, 'Torrified Wheat - US', 'x', 36, 2, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (587, NULL, 'Turbinado - US', 'x', 44, 10, 40, true, true, '2014-01-20 21:19:06.69', NULL, 'Sugars');
INSERT INTO "Fermentable" VALUES (588, NULL, 'Vienna - DE', 'x', 37, 4, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (589, NULL, 'Vienna - UK', 'x', 35, 4, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Kilned Malts');
INSERT INTO "Fermentable" VALUES (590, NULL, 'Wheat Malt - DE', 'x', 37, 2, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (591, NULL, 'Wheat - UK', 'x', 37, 2, 10, true, true, '2014-01-20 21:19:06.69', NULL, 'Adjuncts');
INSERT INTO "Fermentable" VALUES (592, NULL, 'White Sorghum Syrup- US', 'x', 44, 1, 40, true, true, '2014-01-20 21:19:06.69', NULL, 'Sugars');


--
-- Data for Name: FermentableUsageType; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "FermentableUsageType" VALUES (10, 'Mash');
INSERT INTO "FermentableUsageType" VALUES (20, 'Extract');
INSERT INTO "FermentableUsageType" VALUES (30, 'Steep');
INSERT INTO "FermentableUsageType" VALUES (40, 'Late Addition');


--
-- Data for Name: Hop; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "Hop" VALUES (1, NULL, 'Ahtanum ', NULL, 6, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (2, NULL, 'Amarillo ', NULL, 9, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (3, NULL, 'Cascade ', NULL, 5.79999999999999982, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (5, NULL, 'Centennial ', NULL, 10.5, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (6, NULL, 'Chinook ', NULL, 13, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (7, NULL, 'Citra ', NULL, 12, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (8, NULL, 'Cluster ', NULL, 7, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (9, NULL, 'Columbus ', NULL, 15, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (10, NULL, 'Crystal ', NULL, 4.5, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (11, NULL, 'Fuggles', NULL, 4.79999999999999982, true, true, '2012-04-28 22:42:46.597', NULL, 'England', 'UK Hops');
INSERT INTO "Hop" VALUES (12, NULL, 'Galena ', NULL, 13, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (13, NULL, 'Glacier ', NULL, 5.59999999999999964, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (14, NULL, 'Goldings', NULL, 5, true, true, '2012-04-28 22:42:46.597', NULL, NULL, NULL);
INSERT INTO "Hop" VALUES (15, NULL, 'Hallertau ', NULL, 4.5, true, true, '2012-04-28 22:42:46.597', NULL, NULL, 'German Hops');
INSERT INTO "Hop" VALUES (16, NULL, 'Horizon ', NULL, 12, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (17, NULL, 'Liberty ', NULL, 4, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (18, NULL, 'Magnum ', NULL, 12, true, true, '2012-04-28 22:42:46.597', NULL, 'Germany', 'German Hops');
INSERT INTO "Hop" VALUES (19, NULL, 'Millennium ', NULL, 15.5, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (20, NULL, 'Mt. Hood ', NULL, 6, true, true, '2012-04-28 22:42:46.597', NULL, NULL, 'US Hops');
INSERT INTO "Hop" VALUES (21, NULL, 'Mt. Rainier ', NULL, 6, true, true, '2012-04-28 22:42:46.597', NULL, NULL, 'US Hops');
INSERT INTO "Hop" VALUES (22, NULL, 'Newport ', NULL, 15.3000000000000007, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (23, NULL, 'Northern Brewer ', NULL, 9, true, true, '2012-04-28 22:42:46.597', NULL, 'England', 'UK Hops');
INSERT INTO "Hop" VALUES (24, NULL, 'Nugget ', NULL, 13.3000000000000007, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (25, NULL, 'Palisade ', NULL, 7.5, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (26, NULL, 'Perle ', NULL, 8.30000000000000071, true, true, '2012-04-28 22:42:46.597', NULL, 'Germany', 'German Hops');
INSERT INTO "Hop" VALUES (27, NULL, 'Saaz ', NULL, 3.79999999999999982, true, true, '2012-04-28 22:42:46.597', NULL, 'Czech Republic', NULL);
INSERT INTO "Hop" VALUES (28, NULL, 'Santiam ', NULL, 6, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (29, NULL, 'Simcoe ', NULL, 13, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (30, NULL, 'Sorachi Ace ', NULL, 13, true, true, '2012-04-28 22:42:46.597', NULL, 'Japan', 'German Hops');
INSERT INTO "Hop" VALUES (31, NULL, 'Sterling ', NULL, 7.5, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (32, NULL, 'Styrian Aurora ', NULL, 8.30000000000000071, true, true, '2012-04-28 22:42:46.597', NULL, 'Slovenia', NULL);
INSERT INTO "Hop" VALUES (33, NULL, 'Styrian Bobek ', NULL, 5.29999999999999982, true, true, '2012-04-28 22:42:46.597', NULL, 'Slovenia', NULL);
INSERT INTO "Hop" VALUES (34, NULL, 'Styrian Celeia ', NULL, 4.5, true, true, '2012-04-28 22:42:46.597', NULL, 'Slovenia', NULL);
INSERT INTO "Hop" VALUES (35, NULL, 'Styrian Goldings', NULL, 5.25, true, true, '2012-04-28 22:42:46.597', NULL, NULL, NULL);
INSERT INTO "Hop" VALUES (36, NULL, 'Admiral ', NULL, 14.9000000000000004, true, true, '2012-04-28 22:42:46.597', NULL, 'England', 'UK Hops');
INSERT INTO "Hop" VALUES (37, NULL, 'Bramling Cross ', NULL, 6, true, true, '2012-04-28 22:42:46.597', NULL, 'England', 'UK Hops');
INSERT INTO "Hop" VALUES (38, NULL, 'Challenger ', NULL, 7, true, true, '2012-04-28 22:42:46.597', NULL, 'England', 'UK Hops');
INSERT INTO "Hop" VALUES (39, NULL, 'East Kent Goldings', NULL, 5.5, true, true, '2012-04-28 22:42:46.597', NULL, NULL, 'UK Hops');
INSERT INTO "Hop" VALUES (40, NULL, 'First Gold ', NULL, 7.5, true, true, '2012-04-28 22:42:46.597', NULL, 'England', 'UK Hops');
INSERT INTO "Hop" VALUES (42, NULL, 'Northdown ', NULL, 8, true, true, '2012-04-28 22:42:46.597', NULL, 'England', 'UK Hops');
INSERT INTO "Hop" VALUES (43, NULL, 'Phoenix ', NULL, 10, true, true, '2012-04-28 22:42:46.597', NULL, 'England', 'UK Hops');
INSERT INTO "Hop" VALUES (44, NULL, 'Pilgrim ', NULL, 11, true, true, '2012-04-28 22:42:46.597', NULL, 'England', 'UK Hops');
INSERT INTO "Hop" VALUES (45, NULL, 'Pioneer ', NULL, 8.5, true, true, '2012-04-28 22:42:46.597', NULL, 'England', 'UK Hops');
INSERT INTO "Hop" VALUES (46, NULL, 'Progress ', NULL, 5.5, true, true, '2012-04-28 22:42:46.597', NULL, 'England', 'UK Hops');
INSERT INTO "Hop" VALUES (47, NULL, 'Target ', NULL, 11, true, true, '2012-04-28 22:42:46.597', NULL, 'England', 'UK Hops');
INSERT INTO "Hop" VALUES (48, NULL, 'Whitbread Golding (Wgv)', NULL, 6.5, true, true, '2012-04-28 22:42:46.597', NULL, NULL, 'UK Hops');
INSERT INTO "Hop" VALUES (60, NULL, 'Summit ', NULL, 17.5, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (61, NULL, 'Tettnang ', NULL, 4.5, true, true, '2012-04-28 22:42:46.597', NULL, 'Germany', 'German Hops');
INSERT INTO "Hop" VALUES (62, NULL, 'Vanguard ', NULL, 5.5, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (63, NULL, 'Warrior ', NULL, 16, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (64, NULL, 'Willamette ', NULL, 5, true, true, '2012-04-28 22:42:46.597', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (65, NULL, 'Galaxy', NULL, 14.1999999999999993, true, true, '2012-04-28 22:42:46.597', NULL, 'Australia', NULL);
INSERT INTO "Hop" VALUES (67, NULL, 'Strisselspalt ', NULL, 4, true, true, '2012-04-28 22:42:46.597', NULL, NULL, NULL);
INSERT INTO "Hop" VALUES (68, NULL, 'Brewer''s Gold ', NULL, 7, true, true, '2012-04-28 22:42:46.597', NULL, 'Germany', 'German Hops');
INSERT INTO "Hop" VALUES (70, NULL, 'Herkules ', NULL, 3.5, true, true, '2012-04-28 22:42:46.597', NULL, NULL, 'UK Hops');
INSERT INTO "Hop" VALUES (71, NULL, 'Hersbrucker ', NULL, 14.5, true, true, '2012-04-28 22:42:46.597', NULL, NULL, 'German Hops');
INSERT INTO "Hop" VALUES (73, NULL, 'Merkur ', NULL, 13.5, true, true, '2012-04-28 22:42:46.597', NULL, NULL, 'German Hops');
INSERT INTO "Hop" VALUES (75, NULL, 'Opal ', NULL, 6.5, true, true, '2012-04-28 22:42:46.597', NULL, NULL, 'German Hops');
INSERT INTO "Hop" VALUES (77, NULL, 'Saphir ', NULL, 3.25, true, true, '2012-04-28 22:42:46.597', NULL, NULL, 'German Hops');
INSERT INTO "Hop" VALUES (78, NULL, 'Spalter Select ', NULL, 4.75, true, true, '2012-04-28 22:42:46.597', NULL, NULL, 'German Hops');
INSERT INTO "Hop" VALUES (79, NULL, 'Smaragd', NULL, 5, true, true, '2012-04-28 22:42:46.597', NULL, NULL, 'German Hops');
INSERT INTO "Hop" VALUES (80, NULL, 'Spalt ', NULL, 4, true, true, '2012-04-28 22:42:46.597', NULL, NULL, 'German Hops');
INSERT INTO "Hop" VALUES (81, NULL, 'Taurus ', NULL, 5, true, true, '2012-04-28 22:42:46.597', NULL, NULL, 'German Hops');
INSERT INTO "Hop" VALUES (83, NULL, 'Tradition ', NULL, 6, true, true, '2012-04-28 22:42:46.597', NULL, NULL, 'German Hops');
INSERT INTO "Hop" VALUES (86, NULL, 'Motueka ', NULL, 7, true, true, '2012-04-28 22:42:46.597', NULL, NULL, 'New Zealand Hops');
INSERT INTO "Hop" VALUES (116, NULL, 'HopShot', NULL, 8, true, true, '2013-01-30 00:00:00', NULL, NULL, 'US Hops');
INSERT INTO "Hop" VALUES (117, NULL, 'Apollo', NULL, 20.5, true, true, '2013-01-30 21:43:54.62', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (118, NULL, 'Eroica', NULL, 10.5, true, true, '2013-01-30 21:43:54.62', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (119, NULL, 'Feux-Coeur Francais', NULL, 4.29999999999999982, true, true, '2013-01-30 21:43:54.62', NULL, 'Australia', NULL);
INSERT INTO "Hop" VALUES (123, NULL, 'Green Bullet', NULL, 12.5, true, true, '2013-01-30 21:43:54.62', NULL, 'New Zealand', 'New Zealand Hops');
INSERT INTO "Hop" VALUES (124, NULL, 'Greenburg', NULL, 5.20000000000000018, true, true, '2013-01-30 21:43:54.62', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (126, NULL, 'Herald', NULL, 12, true, true, '2013-01-30 21:43:54.62', NULL, 'England', 'UK Hops');
INSERT INTO "Hop" VALUES (129, NULL, 'Lublin', NULL, 4, true, true, '2013-01-30 21:43:54.62', NULL, 'Poland', NULL);
INSERT INTO "Hop" VALUES (135, NULL, 'Pacific Gem', NULL, 15, true, true, '2013-01-30 21:43:54.62', NULL, 'New Zealand', 'New Zealand Hops');
INSERT INTO "Hop" VALUES (136, NULL, 'Pacific Jade', NULL, 13, true, true, '2013-01-30 21:43:54.62', NULL, 'New Zealand', 'New Zealand Hops');
INSERT INTO "Hop" VALUES (137, NULL, 'Pacifica', NULL, 5.5, true, true, '2013-01-30 21:43:54.62', NULL, 'New Zealand', 'New Zealand Hops');
INSERT INTO "Hop" VALUES (138, NULL, 'Pilot', NULL, 10.5, true, true, '2013-01-30 21:43:54.62', NULL, 'England', 'UK Hops');
INSERT INTO "Hop" VALUES (139, NULL, 'Polnischer Lublin', NULL, 3.75, true, true, '2013-01-30 21:43:54.62', NULL, 'Poland', NULL);
INSERT INTO "Hop" VALUES (140, NULL, 'Pride of Ringwood', NULL, 8.5, true, true, '2013-01-30 21:43:54.62', NULL, 'Australia', NULL);
INSERT INTO "Hop" VALUES (141, NULL, 'Riwaka', NULL, 5.5, true, true, '2013-01-30 21:43:54.62', NULL, 'New Zealand', 'New Zealand Hops');
INSERT INTO "Hop" VALUES (142, NULL, 'San Juan Ruby Red', NULL, 7.00999999999999979, true, true, '2013-01-30 21:43:54.62', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (144, NULL, 'Satus', NULL, 13.25, true, true, '2013-01-30 21:43:54.62', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (145, NULL, 'Select', NULL, 5, true, true, '2013-01-30 21:43:54.62', NULL, 'Germany', 'German Hops');
INSERT INTO "Hop" VALUES (147, NULL, 'Southern Cross', NULL, 12.5, true, true, '2013-01-30 21:43:54.62', NULL, 'New Zealand', 'New Zealand Hops');
INSERT INTO "Hop" VALUES (151, NULL, 'Tardif de Bourgogne', NULL, 4.29999999999999982, true, true, '2013-01-30 21:43:54.62', NULL, 'France', NULL);
INSERT INTO "Hop" VALUES (154, NULL, 'Ultra', NULL, 4.75, true, true, '2013-01-30 21:43:54.62', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (156, NULL, 'Zeus', NULL, 15, true, true, '2013-01-30 21:43:54.62', NULL, 'United States', 'US Hops');
INSERT INTO "Hop" VALUES (275, NULL, '3-6-9 Experimental', 'x', 10.6999999999999993, true, true, '2014-01-20 21:19:14.537', NULL, 'Slovenia', NULL);
INSERT INTO "Hop" VALUES (276, NULL, 'Bravo', 'x', 13, true, true, '2014-01-20 21:19:14.537', NULL, 'United States', NULL);
INSERT INTO "Hop" VALUES (277, NULL, 'Chelan', 'x', 13.25, true, true, '2014-01-20 21:19:14.537', NULL, 'United States', NULL);
INSERT INTO "Hop" VALUES (278, NULL, 'Comet', 'x', 9.5, true, true, '2014-01-20 21:19:14.537', NULL, 'United States', NULL);
INSERT INTO "Hop" VALUES (279, NULL, 'El Dorado', 'x', 16, true, true, '2014-01-20 21:19:14.537', NULL, 'United States', NULL);
INSERT INTO "Hop" VALUES (280, NULL, 'Ella', 'x', 15, true, true, '2014-01-20 21:19:14.537', NULL, 'Australia', NULL);
INSERT INTO "Hop" VALUES (281, NULL, 'Endeavour', 'x', 9.25, true, true, '2014-01-20 21:19:14.537', NULL, 'England', NULL);
INSERT INTO "Hop" VALUES (282, NULL, 'German Spalt Select', 'x', 5.5, true, true, '2014-01-20 21:19:14.537', NULL, 'Germany', NULL);
INSERT INTO "Hop" VALUES (283, NULL, 'Golding', 'x', 4.75, true, true, '2014-01-20 21:19:14.537', NULL, 'England', NULL);
INSERT INTO "Hop" VALUES (284, NULL, 'Golding', 'x', 4.5, true, true, '2014-01-20 21:19:14.537', NULL, 'United States', NULL);
INSERT INTO "Hop" VALUES (285, NULL, 'Hallertauer Aroma', 'x', 7.5, true, true, '2014-01-20 21:19:14.537', NULL, 'New Zealand', NULL);
INSERT INTO "Hop" VALUES (286, NULL, 'Hallertauer Mittelfrüh', 'x', 4.25, true, true, '2014-01-20 21:19:14.537', NULL, 'Germany', NULL);
INSERT INTO "Hop" VALUES (287, NULL, 'Hallertau Gold', 'x', 6.25, true, true, '2014-01-20 21:19:14.537', NULL, 'Germany', NULL);
INSERT INTO "Hop" VALUES (288, NULL, 'Kohatu', 'x', 6.5, true, true, '2014-01-20 21:19:14.537', NULL, 'Australia', NULL);
INSERT INTO "Hop" VALUES (289, NULL, 'Olympic', 'x', 12, true, true, '2014-01-20 21:19:14.537', NULL, 'United States', NULL);
INSERT INTO "Hop" VALUES (290, NULL, 'Polaris', 'x', 21.3000000000000007, true, true, '2014-01-20 21:19:14.537', NULL, 'Germany', NULL);
INSERT INTO "Hop" VALUES (291, NULL, 'Polish Lublin', 'x', 3.75, true, true, '2014-01-20 21:19:14.537', NULL, 'Poland', NULL);
INSERT INTO "Hop" VALUES (292, NULL, 'Rakau', 'x', 12, true, true, '2014-01-20 21:19:14.537', NULL, 'Australia', NULL);
INSERT INTO "Hop" VALUES (293, NULL, 'Sticklebract', 'x', 13.5, true, true, '2014-01-20 21:19:14.537', NULL, 'Australia', NULL);
INSERT INTO "Hop" VALUES (294, NULL, 'Summer', 'x', 5.95000000000000018, true, true, '2014-01-20 21:19:14.537', NULL, 'Australia', NULL);
INSERT INTO "Hop" VALUES (295, NULL, 'Super Galena', 'x', 12.9000000000000004, true, true, '2014-01-20 21:19:14.537', NULL, 'United States', NULL);
INSERT INTO "Hop" VALUES (296, NULL, 'Super Pride', 'x', 14, true, true, '2014-01-20 21:19:14.537', NULL, 'Australia', NULL);
INSERT INTO "Hop" VALUES (297, NULL, 'Tettnang', 'x', 4.5, true, true, '2014-01-20 21:19:14.537', NULL, 'United States', NULL);
INSERT INTO "Hop" VALUES (298, NULL, 'Topaz', 'x', 16.3999999999999986, true, true, '2014-01-20 21:19:14.537', NULL, 'Australia', NULL);
INSERT INTO "Hop" VALUES (299, NULL, 'Wai-iti', 'x', 3.5, true, true, '2014-01-20 21:19:14.537', NULL, 'New Zealand', NULL);
INSERT INTO "Hop" VALUES (300, NULL, 'Waimea', 'x', 14.4000000000000004, true, true, '2014-01-20 21:19:14.537', NULL, 'New Zealand', NULL);
INSERT INTO "Hop" VALUES (301, NULL, 'WGV', 'x', 6, true, true, '2014-01-20 21:19:14.537', NULL, 'England', NULL);
INSERT INTO "Hop" VALUES (302, NULL, 'Yakima Cluster', 'x', 7.25, true, true, '2014-01-20 21:19:14.537', NULL, 'United States', NULL);


--
-- Data for Name: HopType; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "HopType" VALUES (10, 'Leaf');
INSERT INTO "HopType" VALUES (20, 'Pellet');
INSERT INTO "HopType" VALUES (30, 'Plug');


--
-- Data for Name: HopUsageType; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "HopUsageType" VALUES (5, 'FirstWort');
INSERT INTO "HopUsageType" VALUES (10, 'Mash');
INSERT INTO "HopUsageType" VALUES (20, 'Boil');
INSERT INTO "HopUsageType" VALUES (30, 'Primary');
INSERT INTO "HopUsageType" VALUES (40, 'Secondary');
INSERT INTO "HopUsageType" VALUES (50, 'FlameOut');
INSERT INTO "HopUsageType" VALUES (60, 'DryHop');


--
-- Data for Name: IbuFormula; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "IbuFormula" VALUES (10, 'Tinseth');
INSERT INTO "IbuFormula" VALUES (20, 'Rager');
INSERT INTO "IbuFormula" VALUES (30, 'Brewgr');


--
-- Data for Name: IngredientCategory; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "IngredientCategory" VALUES (10, 'Adjuncts', 60);
INSERT INTO "IngredientCategory" VALUES (10, 'Base Malts', 30);
INSERT INTO "IngredientCategory" VALUES (10, 'Caramel Malts', 40);
INSERT INTO "IngredientCategory" VALUES (10, 'Dry Malt Extracts', 20);
INSERT INTO "IngredientCategory" VALUES (10, 'Liquid Malt Extracts', 10);
INSERT INTO "IngredientCategory" VALUES (10, 'Other', 1000);
INSERT INTO "IngredientCategory" VALUES (10, 'Roasted Malts', 50);
INSERT INTO "IngredientCategory" VALUES (10, 'Sugars', 70);
INSERT INTO "IngredientCategory" VALUES (20, 'German Hops', 30);
INSERT INTO "IngredientCategory" VALUES (20, 'New Zealand Hops', 40);
INSERT INTO "IngredientCategory" VALUES (20, 'Other', 1000);
INSERT INTO "IngredientCategory" VALUES (20, 'UK Hops', 20);
INSERT INTO "IngredientCategory" VALUES (20, 'US Hops', 10);
INSERT INTO "IngredientCategory" VALUES (30, 'Other', 1000);
INSERT INTO "IngredientCategory" VALUES (30, 'White Labs', 10);
INSERT INTO "IngredientCategory" VALUES (30, 'Wyeast', 20);


--
-- Data for Name: IngredientType; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "IngredientType" VALUES (10, 'Fermentable');
INSERT INTO "IngredientType" VALUES (20, 'Hop');
INSERT INTO "IngredientType" VALUES (30, 'Yeast');
INSERT INTO "IngredientType" VALUES (40, 'Adjunct');


--
-- Data for Name: MashStep; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "MashStep" VALUES (2, NULL, 'Acid Rest', NULL, true, true, '2014-02-04 14:57:46.98', NULL, NULL);
INSERT INTO "MashStep" VALUES (4, NULL, 'Beta-Glucan Rest', NULL, true, true, '2014-02-04 14:58:21.153', NULL, NULL);
INSERT INTO "MashStep" VALUES (5, NULL, 'Dextrinization Rest', NULL, true, true, '2014-02-04 14:58:36.97', NULL, NULL);
INSERT INTO "MashStep" VALUES (6, NULL, 'Maltose Rest', NULL, true, true, '2014-02-04 14:58:54.07', NULL, NULL);
INSERT INTO "MashStep" VALUES (7, NULL, 'Mash-Out', NULL, true, true, '2014-02-04 14:59:28.62', NULL, NULL);
INSERT INTO "MashStep" VALUES (8, NULL, 'Protein Rest', NULL, true, true, '2014-02-04 14:59:40.697', NULL, NULL);
INSERT INTO "MashStep" VALUES (9, NULL, 'Saccharification Rest', NULL, true, true, '2014-02-04 14:59:52.41', NULL, NULL);


--
-- Data for Name: NewsletterSignup; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: NotificationType; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "NotificationType" VALUES (10, 'Recipe Comment');
INSERT INTO "NotificationType" VALUES (20, 'Site Features');
INSERT INTO "NotificationType" VALUES (30, 'Site Outages');
INSERT INTO "NotificationType" VALUES (40, 'Brewer Follow');
INSERT INTO "NotificationType" VALUES (50, 'RecipeBrewComment');


--
-- Data for Name: OAuthProvider; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "OAuthProvider" VALUES (10, 'Facebook', true);


--
-- Data for Name: Partner; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: PartnerSendToShopIngredient; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: PartnerSendToShopSettings; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: PartnerService; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: PartnerServiceType; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "PartnerServiceType" VALUES (10, 'SendToShop');


--
-- Data for Name: Recipe; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: RecipeAdjunct; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: RecipeBrew; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: RecipeComment; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: RecipeFermentable; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: RecipeHop; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: RecipeMashStep; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: RecipeStep; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: RecipeType; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "RecipeType" VALUES (10, 'All Grain');
INSERT INTO "RecipeType" VALUES (20, 'Extract');
INSERT INTO "RecipeType" VALUES (30, 'Partial Mash');


--
-- Data for Name: RecipeYeast; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: SendToShopFormat; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "SendToShopFormat" VALUES (10, 'Email');


--
-- Data for Name: SendToShopMethod; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "SendToShopMethod" VALUES (10, 'Email');


--
-- Data for Name: SendToShopOrder; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: SendToShopOrderItem; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: SendToShopOrderStatus; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "SendToShopOrderStatus" VALUES (-100, 'Cancelled');
INSERT INTO "SendToShopOrderStatus" VALUES (0, 'Created');
INSERT INTO "SendToShopOrderStatus" VALUES (10, 'Sent To Shop');
INSERT INTO "SendToShopOrderStatus" VALUES (20, 'In Progress');
INSERT INTO "SendToShopOrderStatus" VALUES (30, 'On Hold');
INSERT INTO "SendToShopOrderStatus" VALUES (90, 'Ready For Pickup');
INSERT INTO "SendToShopOrderStatus" VALUES (100, 'Picked Up');


--
-- Data for Name: TastingNote; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: UnitType; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "UnitType" VALUES (10, 'US Standard');
INSERT INTO "UnitType" VALUES (20, 'Metric');


--
-- Data for Name: User; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: UserAdmin; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: UserAuthToken; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: UserConnection; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: UserFeedback; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: UserLogin; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: UserNotificationType; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: UserOAuthUserId; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: UserPartnerAdmin; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: UserSuggestion; Type: TABLE DATA; Schema: dbo; Owner: postgres
--



--
-- Data for Name: Yeast; Type: TABLE DATA; Schema: dbo; Owner: postgres
--

INSERT INTO "Yeast" VALUES (125, NULL, 'Brewferm Brewferm Blanche', 'Ferments clean with little or no sulphur.', 0.800000000000000044, true, true, '2012-04-30 21:34:24.453', NULL, 'Other');
INSERT INTO "Yeast" VALUES (126, NULL, 'Brewferm Brewferm Lager', 'Develops Witbeer aromas like banana and clove.', 0.800000000000000044, true, true, '2012-04-30 21:34:24.453', NULL, 'Other');
INSERT INTO "Yeast" VALUES (127, NULL, 'Coopers Coopers Homebrew Yeast', 'Clean, round flavor profile.', 0.800000000000000044, true, true, '2012-04-30 21:34:24.453', NULL, 'Other');
INSERT INTO "Yeast" VALUES (128, NULL, 'Danstar Nottingham', 'Neutral for an ale yeast; fruity estery aromas.', 0.800000000000000044, true, true, '2012-04-30 21:34:24.453', NULL, 'Other');
INSERT INTO "Yeast" VALUES (129, NULL, 'Danstar Windsor', 'Full-bodied, fruity English ale.', 0.699999999999999956, true, true, '2012-04-30 21:34:24.453', NULL, 'Other');
INSERT INTO "Yeast" VALUES (130, NULL, 'Fermentis Fermentis US 56', 'Clean with mild flavor for a wide range of styles.', 0.770000000000000018, false, true, '2012-04-30 21:34:24.453', NULL, 'Other');
INSERT INTO "Yeast" VALUES (131, NULL, 'Fermentis Safale S-04', 'English ale yeast selected for its fast fermentation character and its ability to form a compact sediment at the end of fermentation, helping to improve
beer clarity. Recommended for the production of a large range of ales and specially adapted to cask-conditioned ones and fermentation in cylindoconical
tanks.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'Fermentis');
INSERT INTO "Yeast" VALUES (132, NULL, 'Fermentis Safbrew S-33', 'General purpose ale yeast with neutral flavor profiles. Its low attenuation gives beers with a very good length on the palate. Particularly recommended
for specialty ales and trappist type beers. Yeast with a good sedimentation: forms no clumps but a powdery haze when resuspended in
the beer.', 0.699999999999999956, true, true, '2012-04-30 21:34:24.453', NULL, 'Fermentis');
INSERT INTO "Yeast" VALUES (133, NULL, 'Fermentis Safbrew T-58', 'Specialty yeast selected for its estery somewhat peppery and spicy flavor development. Yeast with a good sedimentation: forms no clumps but a
powdery haze when resuspended in the beer.', 0.699999999999999956, true, true, '2012-04-30 21:34:24.453', NULL, 'Fermentis');
INSERT INTO "Yeast" VALUES (134, NULL, 'Fermentis Saflager S-23', 'Produces a fruit esterness in lagers.', 0.800000000000000044, true, true, '2012-04-30 21:34:24.453', NULL, 'Other');
INSERT INTO "Yeast" VALUES (135, NULL, 'Muntons Muntons Premium Gold', 'Clean balanced ale yeast for 100% malt recipies.', 0.800000000000000044, true, true, '2012-04-30 21:34:24.453', NULL, 'Other');
INSERT INTO "Yeast" VALUES (136, NULL, 'Muntons Muntons Standard Yeast', 'Clean well balanced ale yeast.', 0.800000000000000044, true, true, '2012-04-30 21:34:24.453', NULL, 'Other');
INSERT INTO "Yeast" VALUES (137, NULL, 'Siebel Inst. Alt Ale BRY 144', 'Full-flavoured but clean tasting with estery flavour.', 0.800000000000000044, true, true, '2012-04-30 21:34:24.453', NULL, 'Other');
INSERT INTO "Yeast" VALUES (138, NULL, 'Siebel Inst. American Ale BRY 96', 'Very clean ale flavor.', 0.800000000000000044, true, true, '2012-04-30 21:34:24.453', NULL, 'Other');
INSERT INTO "Yeast" VALUES (139, NULL, 'Siebel Inst. American Lager BRY 118', 'Produces slightly fruity beer; some residual sugar.', 0.699999999999999956, true, true, '2012-04-30 21:34:24.453', NULL, 'Other');
INSERT INTO "Yeast" VALUES (140, NULL, 'Siebel Inst. Bavarian Weizen BRY 235', 'A very estery beer with mild clove-like spiciness.', 0.699999999999999956, true, true, '2012-04-30 21:34:24.453', NULL, 'Other');
INSERT INTO "Yeast" VALUES (141, NULL, 'Siebel Inst. English Ale BRY 264', 'Clean ale with slightly nutty and estery character.', 0.800000000000000044, true, true, '2012-04-30 21:34:24.453', NULL, 'Other');
INSERT INTO "Yeast" VALUES (142, NULL, 'Siebel Inst. North European Lager BRY 203', 'Well balanced beer, fewer sulfur compounds.', 0.800000000000000044, true, true, '2012-04-30 21:34:24.453', NULL, 'Other');
INSERT INTO "Yeast" VALUES (143, NULL, 'Siebel Inst. Trappist Ale BRY 204', 'Dry, estery flavor with a light, clove-like spiciness.', 0.800000000000000044, true, true, '2012-04-30 21:34:24.453', NULL, 'Other');
INSERT INTO "Yeast" VALUES (144, NULL, 'White Labs 10th Anniversary Blend WLP010', 'Blend of WLP001, WLP002, WLP004 & WLP810.', 0.770000000000000018, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (145, NULL, 'White Labs Abbey Ale WLP530', 'Produces fruitiness and plum characteristics.', 0.770000000000000018, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (146, NULL, 'White Labs Amer. Hefeweizen Ale WLP320', 'Produces a slight amount of banana and clove notes.', 0.719999999999999973, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (147, NULL, 'White Labs Amer. Ale Blend WLP060', 'Blend celebrates the strengths of California ale strains.', 0.760000000000000009, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (148, NULL, 'White Labs American Lager WLP840', 'Dry and clean with a very slight apple fruitiness.', 0.770000000000000018, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (149, NULL, 'White Labs Australian Ale WLP009', 'For a clean, malty and bready beer.', 0.719999999999999973, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (150, NULL, 'White Labs Bastogne Belgian Ale WLP510', 'A high gravity, Trappist style ale yeast.', 0.770000000000000018, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (151, NULL, 'White Labs Bavarian Weizen Ale WLP351', 'Moderately high, spicy phenolic overtones of cloves.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (152, NULL, 'White Labs Bedford British Ale WLP006', 'Good choice for most English style ales.', 0.760000000000000009, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (153, NULL, 'White Labs Belgian Ale WLP550', 'Phenolic and spicy flavours dominate the profile.', 0.810000000000000053, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (154, NULL, 'White Labs Belgian Golden Ale WLP570', 'A combination of fruitiness and phenolic flavors.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (155, NULL, 'White Labs Belgian Saison I WLP565', 'Produces earthy, spicy, and peppery notes.', 0.699999999999999956, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (156, NULL, 'White Labs Belgian Style Ale Blend WLP575', 'Blend of Trappist yeast and Belgian ale yeast', 0.770000000000000018, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (157, NULL, 'White Labs Belgian Wit Ale WLP400', 'Slightly phenolic and tart.', 0.760000000000000009, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (158, NULL, 'White Labs Belgian Wit II Ale WLP410', 'Spicier, sweeter, and less phenolic than WLP400.', 0.719999999999999973, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (159, NULL, 'White Labs British Ale WLP005', 'English strain that produces malty beers.', 0.770000000000000018, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (160, NULL, 'White Labs Burton Ale WLP023', 'Subtle fruity flavors: apple, clover honey and pear.', 0.699999999999999956, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (161, NULL, 'White Labs California Ale V WLP051', 'Produces a fruity, full-bodied beer.', 0.719999999999999973, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (162, NULL, 'White Labs California Ale WLP001', 'Clean flavors accentuate hops; very versatile.', 0.699999999999999956, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (163, NULL, 'White Labs Copenhagen Lager WLP850', 'Clean crisp northern European lager yeast.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (164, NULL, 'White Labs Czech Budejovice Lager WLP802', 'Produces dry and crisp lagers, with low diacetyl.', 0.760000000000000009, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (165, NULL, 'White Labs Dry English ale WLP007', 'Good for high gravity ales with no residuals.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (166, NULL, 'White Labs Dusseldorf Alt WLP036', 'Produces clean, slightly sweet alt beers.', 0.680000000000000049, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (167, NULL, 'White Labs East Coast Ale WLP008', 'Very clean and low esters.', 0.719999999999999973, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (168, NULL, 'White Labs Edinburgh Ale WLP028', 'Malty, strong Scottish ales.', 0.719999999999999973, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (169, NULL, 'White Labs English Ale WLP002', 'Very clear with some residual sweetness.', 0.719999999999999973, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (170, NULL, 'White Labs Essex Ale Yeast WLP022', 'Drier finish than many British ale yeasts', 0.729999999999999982, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (171, NULL, 'White Labs European Ale WLP011', 'Low ester production, giving a clean profile.', 0.67000000000000004, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (172, NULL, 'White Labs German Ale II WLP003', 'Clean, sulfur component that reduces with aging.', 0.719999999999999973, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (173, NULL, 'White Labs German Ale/K÷lsch WLP029', 'A super-clean, lager-like ale.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (174, NULL, 'White Labs German Bock Lager WLP833', 'Produces well balanced beers of malt and hop character.', 0.760000000000000009, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (175, NULL, 'White Labs German Lager WLP830', 'Malty and clean; great for all German lagers.', 0.760000000000000009, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (176, NULL, 'White Labs Hefeweizen Ale WLP300', 'Produces banana and clove nose.', 0.739999999999999991, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (177, NULL, 'White Labs Hefeweizen IV Ale WLP380', 'Crisp, large clove and phenolic aroma and flavor.', 0.760000000000000009, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (178, NULL, 'White Labs Irish Ale WLP004', 'Light fruitiness and slight dry crispness.', 0.760000000000000009, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (179, NULL, 'White Labs London Ale WLP013', 'Dry malty ale yeast for pales, bitters and stouts.', 0.709999999999999964, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (180, NULL, 'White Labs Mexican Lager Yeast WLP940', 'Produces clean lager beer, with a crisp finish.', 0.739999999999999991, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (181, NULL, 'White Labs Oktoberfest/MSrzen WLP820', 'Produces a very malty, bock-like style.', 0.689999999999999947, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (182, NULL, 'White Labs Old Bavarian Lager WLP920', 'Finishes malty with a slight ester profile. Use in beers such as Octoberfest, Bock, and dark lagers.', 0.689999999999999947, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (183, NULL, 'White Labs Pacific Ale WLP041', 'A popular ale yeast from the Pacific Northwest.', 0.67000000000000004, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (184, NULL, 'White Labs Pilsner Lager WLP800', 'Somewhat dry with a malty finish.', 0.739999999999999991, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (185, NULL, 'White Labs Premium Bitter Ale WLP026', 'Gives a mild but complex estery character.', 0.719999999999999973, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (186, NULL, 'White Labs San Francisco Lager WLP810', 'For California Common type beer.', 0.67000000000000004, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (187, NULL, 'White Labs So. German Lager WLP838', 'A malty finish and balanced aroma.', 0.719999999999999973, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (188, NULL, 'White Labs Southwold Ale WLP025', 'Complex fruits and citrus flavors.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (189, NULL, 'White Labs Super High Gravity WLP099', 'High gravity yeast, ferments up to 25% alcohol.', 0.760000000000000009, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (190, NULL, 'White Labs Trappist Ale WLP500', 'Distinctive fruitiness and plum characteristics.', 0.770000000000000018, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (191, NULL, 'White Labs Whitbread Ale WLP017', 'Brittish style, slightly fruity with a hint of sulfur.', 0.699999999999999956, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (192, NULL, 'White Labs Zurich Lager Yeast WLP885', 'Swiss style lager yeast with minimal sulfer and diacetyl production.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'White Labs');
INSERT INTO "Yeast" VALUES (193, NULL, 'Wyeast American Ale 1056', 'Well balanced. Ferments dry, finishes soft.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (194, NULL, 'Wyeast American Ale II 1272', 'Slightly nutty, soft, clean and tart finish.', 0.739999999999999991, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (195, NULL, 'Wyeast American Lager 2035', 'Bold, complex and aromatic; slight diacetyl.', 0.770000000000000018, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (196, NULL, 'Wyeast American Wheat 1010', 'Produces a dry, slightly tart, crisp beer.', 0.760000000000000009, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (197, NULL, 'Wyeast Bavarian Lager 2206', 'Produces rich, malty, full-bodied beers.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (198, NULL, 'Wyeast Bavarian Wheat 3056', 'Produces mildly estery and phenolic wheat beers.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (199, NULL, 'Wyeast Bavarian Wheat 3638', 'Balance banana esters w/ apple and plum esters.', 0.729999999999999982, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (200, NULL, 'Wyeast Belgian Abbey II 1762', 'Slightly fruity with a dry finish.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (201, NULL, 'Wyeast Belgian Ale 1214', 'Abbey-style, top-fermenting yeast for high gravity.', 0.739999999999999991, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (202, NULL, 'Wyeast Belgian Ardennes 3522', 'Mild fruitiness with complex spicy character.', 0.739999999999999991, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (203, NULL, 'Wyeast Belgian Lambic Blend 3278', 'Rich, earthy aroma and acidic finish.', 0.699999999999999956, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (204, NULL, 'Wyeast Belgian Saison 3724', 'Very tart and dry with spicy and bubblegum aromatics', 0.780000000000000027, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (205, NULL, 'Wyeast Belgian Strong Ale 1388', 'Fruity nose and palate, dry, tart finish.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (206, NULL, 'Wyeast Belgian Wheat 3942', 'Apple and plum like nose with dry finish.', 0.739999999999999991, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (207, NULL, 'Wyeast Belgian Witbier 3944', 'Alcohol tolerant, with tart, slight phenolic profile.', 0.739999999999999991, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (208, NULL, 'Wyeast Biere de Garde', 'Low to moderate ester production with mild spicyness', 0.780000000000000027, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (209, NULL, 'Wyeast Bohemian Lager 2124', 'Ferments clean and malty.', 0.709999999999999964, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (210, NULL, 'Wyeast Brettan. Bruxellensis 3112', 'Produces classic lambic characteristics.', 0.599999999999999978, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (211, NULL, 'Wyeast Brettan. Lambicus 5526 ', 'Pie cherry-like flavor and sourness.', 0.599999999999999978, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (212, NULL, 'Wyeast British Ale 1098', 'Ferments dry and crisp, slightly tart and fruity.', 0.739999999999999991, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (213, NULL, 'Wyeast British Ale II 1335', 'Malty flavor, crisp finish, clean, fairly dry.', 0.739999999999999991, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (214, NULL, 'Wyeast British Cask Ale 1026', 'Produces nice malt profile with a hint of fruit.', 0.760000000000000009, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (215, NULL, 'Wyeast Budvar Lager 2000', 'Malty nose with subtle fruit. Finishes dry and crisp.', 0.729999999999999982, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (216, NULL, 'Wyeast California Lager 2112', 'Produces malty, brilliantly clear beers.', 0.689999999999999947, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (217, NULL, 'Wyeast Canadian/Belgian Style 3864', 'Mild phenolics and low ester profile with tart finish.', 0.770000000000000018, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (218, NULL, 'Wyeast Czech Pils 2278', 'Dry but malty finish.', 0.719999999999999973, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (219, NULL, 'Wyeast Danish Lager 2042', 'Rich Dortmund style with crisp, dry finish.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (220, NULL, 'Wyeast Dutch Castle Yeast 3822', 'Spicy, phenolic and tart in the nose.', 0.760000000000000009, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (221, NULL, 'Wyeast English Special Bitter 1768', 'Produces light fruit ethanol aroma with soft finish.', 0.699999999999999956, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (222, NULL, 'Wyeast European Ale 1338', 'Full-bodied complex strain and dense malty finish.', 0.689999999999999947, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (223, NULL, 'Wyeast European Lager II 2247', 'Clean, very mild flavor, slight sulfur production.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (224, NULL, 'Wyeast Farmhouse Ale 3726', 'Complex aromas dominated by an earthy/spicy note.', 0.780000000000000027, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (225, NULL, 'Wyeast Forbidden Fruit Yeast 3463', 'Phenolic profile, subdued fruitiness.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (226, NULL, 'Wyeast Gambrinus Lager 2002', 'Mild floral aroma with lager characteristics in the nose.', 0.729999999999999982, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (227, NULL, 'Wyeast German Ale 1007', 'Ferments dry and crisp with a mild flavor.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (228, NULL, 'Wyeast German Wheat 3333', 'Sharp, tart crispness, fruity, sherry-like palate.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (229, NULL, 'Wyeast Irish Ale 1084', 'Slight residual diacetyl and fruitiness.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (230, NULL, 'Wyeast K÷lsch 2565', 'Malty with a subdued fruitiness and a crisp finish.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (231, NULL, 'Wyeast Leuven Pale Ale 3538', 'Slight phenolics and spicy aromatic characteristics.', 0.760000000000000009, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (232, NULL, 'Wyeast London Ale 1028', 'Bold and crisp with a rich mineral profile.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (233, NULL, 'Wyeast London Ale III 1318', 'Very light and fruity, with a soft, balanced palate.', 0.729999999999999982, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (234, NULL, 'Wyeast London ESB Ale 1968', 'Rich, malty character with balanced fruitiness.', 0.689999999999999947, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (235, NULL, 'Wyeast Munich Lager 2308', 'Very smooth, well-rounded and full-bodied.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (236, NULL, 'Wyeast North American Lager 2272', 'Malty finish, traditional Canadian lagers.', 0.729999999999999982, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (237, NULL, 'Wyeast Northwest Ale 1332', 'Malty, mildly fruity, good depth and complexity.', 0.689999999999999947, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (238, NULL, 'Wyeast Octoberfest Lager Blend 2633', 'Plenty of malt character and mouth feel. Low in sulfer.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (239, NULL, 'Wyeast Pilsen Lager 2007', 'Smooth malty palate; ferments dry and crisp.', 0.729999999999999982, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (240, NULL, 'Wyeast Ringwood Ale 1187', 'A malty, complex profile that clears well.', 0.689999999999999947, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (241, NULL, 'Wyeast Scottish Ale 1728', 'Suited for Scottish-style ales, high-gravity ales.', 0.709999999999999964, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (242, NULL, 'Wyeast Thames Valley Ale 1275', 'Clean, light malt character with low esters.', 0.739999999999999991, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (243, NULL, 'Wyeast Thames Valley Ale II 1882', 'Slightly fruitier and maltier than 1275.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (244, NULL, 'Wyeast Trappist High Gravity 3787', 'Ferments dry, rich ester profile and malty palate.', 0.790000000000000036, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (245, NULL, 'Wyeast Urquell Lager 2001', 'Mild fruit and floral aroma. Very dry with mouth feel.', 0.729999999999999982, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (246, NULL, 'Wyeast Weihenstephan Weizen 3068', 'A unique, rich and spicy weizen character.', 0.75, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (247, NULL, 'Wyeast Whitbread Ale 1099', 'Mildly malty and slightly fruity.', 0.699999999999999956, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (248, NULL, 'Wyeast Wyeast Ale Blend 1087', 'A blend of the best strains to provide quick starts.', 0.729999999999999982, true, true, '2012-04-30 21:34:24.453', NULL, 'Wyeast');
INSERT INTO "Yeast" VALUES (253, NULL, 'Fermentis Safale US-05', 'American ale yeast producing well balanced beers with low diacetyl and a very clean, crisp end palate. Forms a firm foam head and presents a
very good ability to stay in suspension during fermentation.', 0.810000000000000053, true, true, '2012-09-18 00:17:05.213', NULL, 'Fermentis');
INSERT INTO "Yeast" VALUES (563, NULL, 'Fermentis Safale K-97', 'German ale yeast selected for its ability to form a large firm head when fermenting. Suitable to brew ales with low esters and can be used for
Belgian type wheat beers. Its lower attenuation profile gives beers with a good length on the palate.', 0.810000000000000053, true, true, '2015-02-11 00:00:00', NULL, 'Fermentis');
INSERT INTO "Yeast" VALUES (566, NULL, 'Fermentis Safbrew Abbaye', 'Yeast recommended to brew abbey type beers known for their high alcohol content. It ferments very fast and reveals subtle and well-balanced
aromas.', 0.819999999999999951, true, true, '2015-02-11 00:00:00', NULL, 'Fermentis');
INSERT INTO "Yeast" VALUES (567, NULL, 'Fermentis Safbrew F-2', 'Safbrew F-2 has been selected specifically for secondary fermentation in bottle and in cask. This yeast assimilates very little maltotriose but assimilates
basic sugars (glucose, fructose, saccharose, maltose) and is caracterized by a neutral aroma profile respecting the base beer character.', 0.800000000000000044, true, true, '2015-02-11 00:00:00', NULL, 'Fermentis');
INSERT INTO "Yeast" VALUES (568, NULL, 'Fermentis Safbrew WB-06', 'Specialty yeast selected for wheat beer fermentations. Produces subtle estery and phenol flavor notes typical of wheat beers. Allows to brew beer
with a high drinkability profile and presents a very good ability to suspend during fermentation.', 0.859999999999999987, true, true, '2015-02-11 00:00:00', NULL, 'Fermentis');
INSERT INTO "Yeast" VALUES (569, NULL, 'Fermentis Saflager S-23', 'Bottom fermenting yeast originating from the VLB - Berlin in Germany recommended for the production of fruity and estery lagers. Its lower attenuation
profile gives beers with a good length on the palate.', 0.819999999999999951, true, true, '2015-02-11 00:00:00', NULL, 'Fermentis');
INSERT INTO "Yeast" VALUES (570, NULL, 'Fermentis Saflager S-189', 'Originating from the Hnrlimann brewery in Switzerland. This lager strainÆs attenuation profile allows to brew fairly neutral flavor beers with a high
drinkability.', 0.839999999999999969, true, true, '2015-02-11 00:00:00', NULL, 'Fermentis');
INSERT INTO "Yeast" VALUES (571, NULL, 'Fermentis Saflager W-34/70', 'This famous yeast strain from Weihenstephan in Germany is used world-wide within the brewing industry. Saflager W-34/70 allows to brew beers
with a good balance of floral and fruity aromas and gives clean flavors and high drinkable beers.', 0.82999999999999996, true, true, '2015-02-11 00:00:00', NULL, 'Fermentis');


--
-- Name: adjunct_adjunctid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('adjunct_adjunctid_seq', 27, true);


--
-- Name: brewsession_brewsessionid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('brewsession_brewsessionid_seq', 1, false);


--
-- Name: brewsessioncomment_brewsessioncommentid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('brewsessioncomment_brewsessioncommentid_seq', 1, false);


--
-- Name: content_contentid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('content_contentid_seq', 1, false);


--
-- Name: exceptions_id_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('exceptions_id_seq', 1, false);


--
-- Name: fermentable_fermentableid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('fermentable_fermentableid_seq', 592, true);


--
-- Name: hop_hopid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('hop_hopid_seq', 302, true);


--
-- Name: mashstep_mashstepid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('mashstep_mashstepid_seq', 1, false);


--
-- Name: newslettersignup_newslettersignupid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('newslettersignup_newslettersignupid_seq', 1, false);


--
-- Name: partner_partnerid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('partner_partnerid_seq', 1, false);


--
-- Name: recipe_recipeid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('recipe_recipeid_seq', 1, false);


--
-- Name: recipeadjunct_recipeadjunctid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('recipeadjunct_recipeadjunctid_seq', 1, false);


--
-- Name: recipebrew_recipebrewid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('recipebrew_recipebrewid_seq', 1, false);


--
-- Name: recipecomment_recipecommentid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('recipecomment_recipecommentid_seq', 1, false);


--
-- Name: recipefermentable_recipefermentableid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('recipefermentable_recipefermentableid_seq', 1, false);


--
-- Name: recipehop_recipehopid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('recipehop_recipehopid_seq', 1, false);


--
-- Name: recipemashstep_recipemashstepid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('recipemashstep_recipemashstepid_seq', 1, false);


--
-- Name: recipestep_recipestepid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('recipestep_recipestepid_seq', 1, false);


--
-- Name: recipeyeast_recipeyeastid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('recipeyeast_recipeyeastid_seq', 1, false);


--
-- Name: sendtoshoporder_sendtoshoporderid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('sendtoshoporder_sendtoshoporderid_seq', 1001, false);


--
-- Name: sendtoshoporderitem_sendtoshoporderitemid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('sendtoshoporderitem_sendtoshoporderitemid_seq', 1, false);


--
-- Name: tastingnote_tastingnoteid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('tastingnote_tastingnoteid_seq', 1, false);


--
-- Name: user_userid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('user_userid_seq', 100000, false);


--
-- Name: userauthtoken_userauthtokenid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('userauthtoken_userauthtokenid_seq', 1, false);


--
-- Name: userfeedback_userfeedbackid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('userfeedback_userfeedbackid_seq', 1, false);


--
-- Name: usersuggestion_usersuggestionid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('usersuggestion_usersuggestionid_seq', 1, false);


--
-- Name: yeast_yeastid_seq; Type: SEQUENCE SET; Schema: dbo; Owner: postgres
--

SELECT pg_catalog.setval('yeast_yeastid_seq', 571, true);


--
-- Name: PK_Adjunct; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Adjunct"
    ADD CONSTRAINT "PK_Adjunct" PRIMARY KEY ("AdjunctId");


--
-- Name: PK_AdjunctUsage; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "AdjunctUsageType"
    ADD CONSTRAINT "PK_AdjunctUsage" PRIMARY KEY ("AdjunctUsageTypeId");


--
-- Name: PK_BJCPStyle; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "BjcpStyle"
    ADD CONSTRAINT "PK_BJCPStyle" PRIMARY KEY ("SubCategoryId");


--
-- Name: PK_BjcpStyleUrlFriendlyName; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "BjcpStyleUrlFriendlyName"
    ADD CONSTRAINT "PK_BjcpStyleUrlFriendlyName" PRIMARY KEY ("SubCategoryId");


--
-- Name: PK_BrewSession; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "BrewSession"
    ADD CONSTRAINT "PK_BrewSession" PRIMARY KEY ("BrewSessionId");


--
-- Name: PK_Comment; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeComment"
    ADD CONSTRAINT "PK_Comment" PRIMARY KEY ("RecipeCommentId");


--
-- Name: PK_Content; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Content"
    ADD CONSTRAINT "PK_Content" PRIMARY KEY ("ContentId");


--
-- Name: PK_ContentType; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "ContentType"
    ADD CONSTRAINT "PK_ContentType" PRIMARY KEY ("ContentTypeId");


--
-- Name: PK_Exceptions; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Exceptions"
    ADD CONSTRAINT "PK_Exceptions" PRIMARY KEY ("Id");


--
-- Name: PK_Fermentable; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Fermentable"
    ADD CONSTRAINT "PK_Fermentable" PRIMARY KEY ("FermentableId");


--
-- Name: PK_FermentableUsageType; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "FermentableUsageType"
    ADD CONSTRAINT "PK_FermentableUsageType" PRIMARY KEY ("FermentableUsageTypeId");


--
-- Name: PK_Hop; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Hop"
    ADD CONSTRAINT "PK_Hop" PRIMARY KEY ("HopId");


--
-- Name: PK_HopType; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "HopType"
    ADD CONSTRAINT "PK_HopType" PRIMARY KEY ("HopTypeId");


--
-- Name: PK_HopUsageType; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "HopUsageType"
    ADD CONSTRAINT "PK_HopUsageType" PRIMARY KEY ("HopUsageTypeId");


--
-- Name: PK_IbuFormula; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "IbuFormula"
    ADD CONSTRAINT "PK_IbuFormula" PRIMARY KEY ("IbuFormulaId");


--
-- Name: PK_IngredientCategory; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "IngredientCategory"
    ADD CONSTRAINT "PK_IngredientCategory" PRIMARY KEY ("IngredientTypeId", "Category");


--
-- Name: PK_IngredientType; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "IngredientType"
    ADD CONSTRAINT "PK_IngredientType" PRIMARY KEY ("IngredientTypeId");


--
-- Name: PK_MashStep; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "MashStep"
    ADD CONSTRAINT "PK_MashStep" PRIMARY KEY ("MashStepId");


--
-- Name: PK_NewsletterSignup; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "NewsletterSignup"
    ADD CONSTRAINT "PK_NewsletterSignup" PRIMARY KEY ("NewsletterSignupId");


--
-- Name: PK_NotificationType; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "NotificationType"
    ADD CONSTRAINT "PK_NotificationType" PRIMARY KEY ("NotificationTypeId");


--
-- Name: PK_OAuthProvider; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "OAuthProvider"
    ADD CONSTRAINT "PK_OAuthProvider" PRIMARY KEY ("OAuthProviderId");


--
-- Name: PK_Partner; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Partner"
    ADD CONSTRAINT "PK_Partner" PRIMARY KEY ("PartnerId");


--
-- Name: PK_PartnerSendToShopIngredient_1; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "PartnerSendToShopIngredient"
    ADD CONSTRAINT "PK_PartnerSendToShopIngredient_1" PRIMARY KEY ("PartnerId", "IngredientTypeId", "IngredientId");


--
-- Name: PK_PartnerSendToShopSettings; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "PartnerSendToShopSettings"
    ADD CONSTRAINT "PK_PartnerSendToShopSettings" PRIMARY KEY ("PartnerId");


--
-- Name: PK_PartnerService; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "PartnerService"
    ADD CONSTRAINT "PK_PartnerService" PRIMARY KEY ("PartnerId", "PartnerServiceTypeId");


--
-- Name: PK_PartnerServiceType; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "PartnerServiceType"
    ADD CONSTRAINT "PK_PartnerServiceType" PRIMARY KEY ("PartnerServiceTypeId");


--
-- Name: PK_Recipe; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Recipe"
    ADD CONSTRAINT "PK_Recipe" PRIMARY KEY ("RecipeId");


--
-- Name: PK_RecipeAdjunct; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeAdjunct"
    ADD CONSTRAINT "PK_RecipeAdjunct" PRIMARY KEY ("RecipeAdjunctId");


--
-- Name: PK_RecipeBrew; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeBrew"
    ADD CONSTRAINT "PK_RecipeBrew" PRIMARY KEY ("RecipeBrewId");


--
-- Name: PK_RecipeBrewComment; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "BrewSessionComment"
    ADD CONSTRAINT "PK_RecipeBrewComment" PRIMARY KEY ("BrewSessionCommentId");


--
-- Name: PK_RecipeFermentable; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeFermentable"
    ADD CONSTRAINT "PK_RecipeFermentable" PRIMARY KEY ("RecipeFermentableId");


--
-- Name: PK_RecipeHop; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeHop"
    ADD CONSTRAINT "PK_RecipeHop" PRIMARY KEY ("RecipeHopId");


--
-- Name: PK_RecipeMashStep; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeMashStep"
    ADD CONSTRAINT "PK_RecipeMashStep" PRIMARY KEY ("RecipeMashStepId");


--
-- Name: PK_RecipeStep; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeStep"
    ADD CONSTRAINT "PK_RecipeStep" PRIMARY KEY ("RecipeStepId");


--
-- Name: PK_RecipeType; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeType"
    ADD CONSTRAINT "PK_RecipeType" PRIMARY KEY ("RecipeTypeId");


--
-- Name: PK_RecipeYeast; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeYeast"
    ADD CONSTRAINT "PK_RecipeYeast" PRIMARY KEY ("RecipeYeastId");


--
-- Name: PK_SendToShopFormat; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "SendToShopFormat"
    ADD CONSTRAINT "PK_SendToShopFormat" PRIMARY KEY ("SendToShopFormatTypeId");


--
-- Name: PK_SendToShopMethod; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "SendToShopMethod"
    ADD CONSTRAINT "PK_SendToShopMethod" PRIMARY KEY ("SendToShopMethodTypeId");


--
-- Name: PK_SendToShopOrder; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "SendToShopOrder"
    ADD CONSTRAINT "PK_SendToShopOrder" PRIMARY KEY ("SendToShopOrderId");


--
-- Name: PK_SendToShopOrderItem; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "SendToShopOrderItem"
    ADD CONSTRAINT "PK_SendToShopOrderItem" PRIMARY KEY ("SendToShopOrderItemId");


--
-- Name: PK_SendToShopOrderStatus; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "SendToShopOrderStatus"
    ADD CONSTRAINT "PK_SendToShopOrderStatus" PRIMARY KEY ("SendToShopOrderStatusId");


--
-- Name: PK_TastingNote; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "TastingNote"
    ADD CONSTRAINT "PK_TastingNote" PRIMARY KEY ("TastingNoteId");


--
-- Name: PK_UnitType; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UnitType"
    ADD CONSTRAINT "PK_UnitType" PRIMARY KEY ("UnitTypeId");


--
-- Name: PK_User; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "User"
    ADD CONSTRAINT "PK_User" PRIMARY KEY ("UserId");


--
-- Name: PK_UserAdmin; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserAdmin"
    ADD CONSTRAINT "PK_UserAdmin" PRIMARY KEY ("UserId");


--
-- Name: PK_UserAuthToken; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserAuthToken"
    ADD CONSTRAINT "PK_UserAuthToken" PRIMARY KEY ("UserAuthTokenId");


--
-- Name: PK_UserConnection; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserConnection"
    ADD CONSTRAINT "PK_UserConnection" PRIMARY KEY ("UserId", "FollowedById");


--
-- Name: PK_UserFeedback; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserFeedback"
    ADD CONSTRAINT "PK_UserFeedback" PRIMARY KEY ("UserFeedbackId");


--
-- Name: PK_UserLogin; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserLogin"
    ADD CONSTRAINT "PK_UserLogin" PRIMARY KEY ("UserId", "LoginDate");


--
-- Name: PK_UserNotificationType; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserNotificationType"
    ADD CONSTRAINT "PK_UserNotificationType" PRIMARY KEY ("UserId", "NotificationTypeId");


--
-- Name: PK_UserOAuthUserId; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserOAuthUserId"
    ADD CONSTRAINT "PK_UserOAuthUserId" PRIMARY KEY ("UserId", "OAuthProviderId");


--
-- Name: PK_UserPartnerAdmin; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserPartnerAdmin"
    ADD CONSTRAINT "PK_UserPartnerAdmin" PRIMARY KEY ("UserId", "PartnerId");


--
-- Name: PK_UserSuggestion; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserSuggestion"
    ADD CONSTRAINT "PK_UserSuggestion" PRIMARY KEY ("UserSuggestionId");


--
-- Name: PK_Yeast; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Yeast"
    ADD CONSTRAINT "PK_Yeast" PRIMARY KEY ("YeastId");


--
-- Name: UC_Name; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Content"
    ADD CONSTRAINT "UC_Name" UNIQUE ("Name");


--
-- Name: UC_ShortName; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Content"
    ADD CONSTRAINT "UC_ShortName" UNIQUE ("ShortName");


--
-- Name: UC_User_EmailAddress; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "User"
    ADD CONSTRAINT "UC_User_EmailAddress" UNIQUE ("EmailAddress");


--
-- Name: UC_User_Username; Type: CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "User"
    ADD CONSTRAINT "UC_User_Username" UNIQUE ("Username");


--
-- Name: User_CalculatedUserName_Trigger; Type: TRIGGER; Schema: dbo; Owner: postgres
--

CREATE TRIGGER "User_CalculatedUserName_Trigger" BEFORE INSERT OR UPDATE ON "User" FOR EACH ROW EXECUTE PROCEDURE "User_CalculatedUserName_Trigger_Function"();


--
-- Name: FK_Adjunct_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Adjunct"
    ADD CONSTRAINT "FK_Adjunct_User" FOREIGN KEY ("CreatedByUserId") REFERENCES "User"("UserId");


--
-- Name: FK_BrewSessionComment_BrewSession; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "BrewSessionComment"
    ADD CONSTRAINT "FK_BrewSessionComment_BrewSession" FOREIGN KEY ("BrewSessionId") REFERENCES "BrewSession"("BrewSessionId");


--
-- Name: FK_BrewSession_Recipe; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "BrewSession"
    ADD CONSTRAINT "FK_BrewSession_Recipe" FOREIGN KEY ("RecipeId") REFERENCES "Recipe"("RecipeId");


--
-- Name: FK_BrewSession_UnitType; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "BrewSession"
    ADD CONSTRAINT "FK_BrewSession_UnitType" FOREIGN KEY ("UnitTypeId") REFERENCES "UnitType"("UnitTypeId");


--
-- Name: FK_BrewSession_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "BrewSession"
    ADD CONSTRAINT "FK_BrewSession_User" FOREIGN KEY ("UserId") REFERENCES "User"("UserId");


--
-- Name: FK_Comment_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeComment"
    ADD CONSTRAINT "FK_Comment_User" FOREIGN KEY ("UserId") REFERENCES "User"("UserId");


--
-- Name: FK_Content_ContentType; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Content"
    ADD CONSTRAINT "FK_Content_ContentType" FOREIGN KEY ("ContentTypeId") REFERENCES "ContentType"("ContentTypeId");


--
-- Name: FK_Content_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Content"
    ADD CONSTRAINT "FK_Content_User" FOREIGN KEY ("CreatedBy") REFERENCES "User"("UserId");


--
-- Name: FK_Content_User1; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Content"
    ADD CONSTRAINT "FK_Content_User1" FOREIGN KEY ("ModifiedBy") REFERENCES "User"("UserId");


--
-- Name: FK_Fermentable_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Fermentable"
    ADD CONSTRAINT "FK_Fermentable_User" FOREIGN KEY ("CreatedByUserId") REFERENCES "User"("UserId");


--
-- Name: FK_Hop_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Hop"
    ADD CONSTRAINT "FK_Hop_User" FOREIGN KEY ("CreatedByUserId") REFERENCES "User"("UserId");


--
-- Name: FK_MashStep_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "MashStep"
    ADD CONSTRAINT "FK_MashStep_User" FOREIGN KEY ("CreatedByUserId") REFERENCES "User"("UserId");


--
-- Name: FK_PartnerSendToShopIngredient_IngredientType; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "PartnerSendToShopIngredient"
    ADD CONSTRAINT "FK_PartnerSendToShopIngredient_IngredientType" FOREIGN KEY ("IngredientTypeId") REFERENCES "IngredientType"("IngredientTypeId");


--
-- Name: FK_PartnerSendToShopIngredient_Partner; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "PartnerSendToShopIngredient"
    ADD CONSTRAINT "FK_PartnerSendToShopIngredient_Partner" FOREIGN KEY ("PartnerId") REFERENCES "Partner"("PartnerId");


--
-- Name: FK_PartnerSendToShopSettings_Partner; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "PartnerSendToShopSettings"
    ADD CONSTRAINT "FK_PartnerSendToShopSettings_Partner" FOREIGN KEY ("PartnerId") REFERENCES "Partner"("PartnerId");


--
-- Name: FK_PartnerSendToShopSettings_SendToShopFormat; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "PartnerSendToShopSettings"
    ADD CONSTRAINT "FK_PartnerSendToShopSettings_SendToShopFormat" FOREIGN KEY ("SendToShopFormatTypeId") REFERENCES "SendToShopFormat"("SendToShopFormatTypeId");


--
-- Name: FK_PartnerSendToShopSettings_SendToShopMethod; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "PartnerSendToShopSettings"
    ADD CONSTRAINT "FK_PartnerSendToShopSettings_SendToShopMethod" FOREIGN KEY ("SendToShopMethodTypeId") REFERENCES "SendToShopMethod"("SendToShopMethodTypeId");


--
-- Name: FK_PartnerSendToShopSettings_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "PartnerSendToShopSettings"
    ADD CONSTRAINT "FK_PartnerSendToShopSettings_User" FOREIGN KEY ("CreatedBy") REFERENCES "User"("UserId");


--
-- Name: FK_PartnerSendToShopSettings_User1; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "PartnerSendToShopSettings"
    ADD CONSTRAINT "FK_PartnerSendToShopSettings_User1" FOREIGN KEY ("ModifiedBy") REFERENCES "User"("UserId");


--
-- Name: FK_PartnerService_Partner; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "PartnerService"
    ADD CONSTRAINT "FK_PartnerService_Partner" FOREIGN KEY ("PartnerId") REFERENCES "Partner"("PartnerId");


--
-- Name: FK_PartnerService_PartnerServiceType; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "PartnerService"
    ADD CONSTRAINT "FK_PartnerService_PartnerServiceType" FOREIGN KEY ("PartnerServiceTypeId") REFERENCES "PartnerServiceType"("PartnerServiceTypeId");


--
-- Name: FK_RecipeAdjunct_Adjunct; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeAdjunct"
    ADD CONSTRAINT "FK_RecipeAdjunct_Adjunct" FOREIGN KEY ("IngredientId") REFERENCES "Adjunct"("AdjunctId");


--
-- Name: FK_RecipeAdjunct_AdjunctUsageType; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeAdjunct"
    ADD CONSTRAINT "FK_RecipeAdjunct_AdjunctUsageType" FOREIGN KEY ("AdjunctUsageTypeId") REFERENCES "AdjunctUsageType"("AdjunctUsageTypeId");


--
-- Name: FK_RecipeAdjunct_Recipe; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeAdjunct"
    ADD CONSTRAINT "FK_RecipeAdjunct_Recipe" FOREIGN KEY ("RecipeId") REFERENCES "Recipe"("RecipeId");


--
-- Name: FK_RecipeBrewComment_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "BrewSessionComment"
    ADD CONSTRAINT "FK_RecipeBrewComment_User" FOREIGN KEY ("UserId") REFERENCES "User"("UserId");


--
-- Name: FK_RecipeBrew_Recipe; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeBrew"
    ADD CONSTRAINT "FK_RecipeBrew_Recipe" FOREIGN KEY ("RecipeId") REFERENCES "Recipe"("RecipeId");


--
-- Name: FK_RecipeBrew_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeBrew"
    ADD CONSTRAINT "FK_RecipeBrew_User" FOREIGN KEY ("BrewedBy") REFERENCES "User"("UserId");


--
-- Name: FK_RecipeComment_Recipe; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeComment"
    ADD CONSTRAINT "FK_RecipeComment_Recipe" FOREIGN KEY ("RecipeId") REFERENCES "Recipe"("RecipeId");


--
-- Name: FK_RecipeFermentable_Fermentable; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeFermentable"
    ADD CONSTRAINT "FK_RecipeFermentable_Fermentable" FOREIGN KEY ("IngredientId") REFERENCES "Fermentable"("FermentableId");


--
-- Name: FK_RecipeFermentable_FermentableUsageType; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeFermentable"
    ADD CONSTRAINT "FK_RecipeFermentable_FermentableUsageType" FOREIGN KEY ("FermentableUsageTypeId") REFERENCES "FermentableUsageType"("FermentableUsageTypeId");


--
-- Name: FK_RecipeFermentable_Recipe; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeFermentable"
    ADD CONSTRAINT "FK_RecipeFermentable_Recipe" FOREIGN KEY ("RecipeId") REFERENCES "Recipe"("RecipeId");


--
-- Name: FK_RecipeHop_Hop; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeHop"
    ADD CONSTRAINT "FK_RecipeHop_Hop" FOREIGN KEY ("IngredientId") REFERENCES "Hop"("HopId");


--
-- Name: FK_RecipeHop_HopType; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeHop"
    ADD CONSTRAINT "FK_RecipeHop_HopType" FOREIGN KEY ("HopTypeId") REFERENCES "HopType"("HopTypeId");


--
-- Name: FK_RecipeHop_HopUsage; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeHop"
    ADD CONSTRAINT "FK_RecipeHop_HopUsage" FOREIGN KEY ("HopUsageTypeId") REFERENCES "HopUsageType"("HopUsageTypeId");


--
-- Name: FK_RecipeHop_Recipe; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeHop"
    ADD CONSTRAINT "FK_RecipeHop_Recipe" FOREIGN KEY ("RecipeId") REFERENCES "Recipe"("RecipeId");


--
-- Name: FK_RecipeMashStep_MashStep; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeMashStep"
    ADD CONSTRAINT "FK_RecipeMashStep_MashStep" FOREIGN KEY ("IngredientId") REFERENCES "MashStep"("MashStepId");


--
-- Name: FK_RecipeMashStep_Recipe; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeMashStep"
    ADD CONSTRAINT "FK_RecipeMashStep_Recipe" FOREIGN KEY ("RecipeId") REFERENCES "Recipe"("RecipeId");


--
-- Name: FK_RecipeStep_Recipe; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeStep"
    ADD CONSTRAINT "FK_RecipeStep_Recipe" FOREIGN KEY ("RecipeId") REFERENCES "Recipe"("RecipeId");


--
-- Name: FK_RecipeYeast_Recipe; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeYeast"
    ADD CONSTRAINT "FK_RecipeYeast_Recipe" FOREIGN KEY ("RecipeId") REFERENCES "Recipe"("RecipeId");


--
-- Name: FK_RecipeYeast_Yeast; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "RecipeYeast"
    ADD CONSTRAINT "FK_RecipeYeast_Yeast" FOREIGN KEY ("IngredientId") REFERENCES "Yeast"("YeastId");


--
-- Name: FK_Recipe_BJCPStyle; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Recipe"
    ADD CONSTRAINT "FK_Recipe_BJCPStyle" FOREIGN KEY ("BjcpStyleSubCategoryId") REFERENCES "BjcpStyle"("SubCategoryId");


--
-- Name: FK_Recipe_Recipe; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Recipe"
    ADD CONSTRAINT "FK_Recipe_Recipe" FOREIGN KEY ("OriginalRecipeId") REFERENCES "Recipe"("RecipeId");


--
-- Name: FK_Recipe_RecipeType; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Recipe"
    ADD CONSTRAINT "FK_Recipe_RecipeType" FOREIGN KEY ("RecipeTypeId") REFERENCES "RecipeType"("RecipeTypeId");


--
-- Name: FK_Recipe_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Recipe"
    ADD CONSTRAINT "FK_Recipe_User" FOREIGN KEY ("CreatedBy") REFERENCES "User"("UserId");


--
-- Name: FK_SendToShopOrderItem_IngredientType; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "SendToShopOrderItem"
    ADD CONSTRAINT "FK_SendToShopOrderItem_IngredientType" FOREIGN KEY ("IngredientTypeId") REFERENCES "IngredientType"("IngredientTypeId");


--
-- Name: FK_SendToShopOrderItem_SendToShopOrder; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "SendToShopOrderItem"
    ADD CONSTRAINT "FK_SendToShopOrderItem_SendToShopOrder" FOREIGN KEY ("SendToShopOrderId") REFERENCES "SendToShopOrder"("SendToShopOrderId");


--
-- Name: FK_SendToShopOrder_Partner; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "SendToShopOrder"
    ADD CONSTRAINT "FK_SendToShopOrder_Partner" FOREIGN KEY ("PartnerId") REFERENCES "Partner"("PartnerId");


--
-- Name: FK_SendToShopOrder_Recipe; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "SendToShopOrder"
    ADD CONSTRAINT "FK_SendToShopOrder_Recipe" FOREIGN KEY ("RecipeId") REFERENCES "Recipe"("RecipeId");


--
-- Name: FK_SendToShopOrder_SendToShopOrderStatus; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "SendToShopOrder"
    ADD CONSTRAINT "FK_SendToShopOrder_SendToShopOrderStatus" FOREIGN KEY ("SendToShopOrderStatusId") REFERENCES "SendToShopOrderStatus"("SendToShopOrderStatusId");


--
-- Name: FK_SendToShopOrder_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "SendToShopOrder"
    ADD CONSTRAINT "FK_SendToShopOrder_User" FOREIGN KEY ("UserId") REFERENCES "User"("UserId");


--
-- Name: FK_TastingNote_BrewSession; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "TastingNote"
    ADD CONSTRAINT "FK_TastingNote_BrewSession" FOREIGN KEY ("BrewSessionId") REFERENCES "BrewSession"("BrewSessionId");


--
-- Name: FK_TastingNote_Recipe; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "TastingNote"
    ADD CONSTRAINT "FK_TastingNote_Recipe" FOREIGN KEY ("RecipeId") REFERENCES "Recipe"("RecipeId");


--
-- Name: FK_TastingNote_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "TastingNote"
    ADD CONSTRAINT "FK_TastingNote_User" FOREIGN KEY ("UserId") REFERENCES "User"("UserId");


--
-- Name: FK_UserAdmin_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserAdmin"
    ADD CONSTRAINT "FK_UserAdmin_User" FOREIGN KEY ("UserId") REFERENCES "User"("UserId");


--
-- Name: FK_UserAuthToken_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserAuthToken"
    ADD CONSTRAINT "FK_UserAuthToken_User" FOREIGN KEY ("UserId") REFERENCES "User"("UserId");


--
-- Name: FK_UserConnection_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserConnection"
    ADD CONSTRAINT "FK_UserConnection_User" FOREIGN KEY ("UserId") REFERENCES "User"("UserId");


--
-- Name: FK_UserConnection_User1; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserConnection"
    ADD CONSTRAINT "FK_UserConnection_User1" FOREIGN KEY ("FollowedById") REFERENCES "User"("UserId");


--
-- Name: FK_UserFeedback_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserFeedback"
    ADD CONSTRAINT "FK_UserFeedback_User" FOREIGN KEY ("UserId") REFERENCES "User"("UserId");


--
-- Name: FK_UserLogin_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserLogin"
    ADD CONSTRAINT "FK_UserLogin_User" FOREIGN KEY ("UserId") REFERENCES "User"("UserId");


--
-- Name: FK_UserNotificationType_NotificationType; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserNotificationType"
    ADD CONSTRAINT "FK_UserNotificationType_NotificationType" FOREIGN KEY ("NotificationTypeId") REFERENCES "NotificationType"("NotificationTypeId");


--
-- Name: FK_UserNotificationType_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserNotificationType"
    ADD CONSTRAINT "FK_UserNotificationType_User" FOREIGN KEY ("UserId") REFERENCES "User"("UserId");


--
-- Name: FK_UserOAuthUserId_OAuthProvider; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserOAuthUserId"
    ADD CONSTRAINT "FK_UserOAuthUserId_OAuthProvider" FOREIGN KEY ("OAuthProviderId") REFERENCES "OAuthProvider"("OAuthProviderId");


--
-- Name: FK_UserOAuthUserId_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserOAuthUserId"
    ADD CONSTRAINT "FK_UserOAuthUserId_User" FOREIGN KEY ("UserId") REFERENCES "User"("UserId");


--
-- Name: FK_UserPartnerAdmin_Partner; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserPartnerAdmin"
    ADD CONSTRAINT "FK_UserPartnerAdmin_Partner" FOREIGN KEY ("PartnerId") REFERENCES "Partner"("PartnerId");


--
-- Name: FK_UserPartnerAdmin_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserPartnerAdmin"
    ADD CONSTRAINT "FK_UserPartnerAdmin_User" FOREIGN KEY ("UserId") REFERENCES "User"("UserId");


--
-- Name: FK_UserSuggestion_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "UserSuggestion"
    ADD CONSTRAINT "FK_UserSuggestion_User" FOREIGN KEY ("UserId") REFERENCES "User"("UserId");


--
-- Name: FK_Yeast_User; Type: FK CONSTRAINT; Schema: dbo; Owner: postgres
--

ALTER TABLE ONLY "Yeast"
    ADD CONSTRAINT "FK_Yeast_User" FOREIGN KEY ("CreatedByUserId") REFERENCES "User"("UserId");


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

