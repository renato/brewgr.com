// -------------------------------------------------------------------------------------------------------
// util Static Class
// -------------------------------------------------------------------------------------------------------
var util =
{
    templateCache: [],

    /// Checks if the user is logged in
    userIsLoggedIn : function() {
        var isLoggedIn = false;
        $.ajax({
            url: "/UserIsLoggedIn",
            cache: false,
            async: false,
            success: function (t) {
                isLoggedIn = (t == "1");
            },
            error: function() {
                isLoggedIn = false;
            }
        });

        return isLoggedIn;
    },

    /// Checks if a value is numeric
    isNumeric: function (value) {
        return !isNaN(Number(value)) && isFinite(value);
    },

    /// Safely rounds a number, omitting decimal places as needed
    safeRound: function (num, multiple) {
        if (typeof multiple === 'undefined') {
            multiple = 10000;
        };
        return Math.round(num * multiple) / multiple;
    },

    /// Applies Data to a Template
    applyTemplate: function (id, data) {
        var template;
        var cacheResult = $.grep(util.templateCache, function (e) { return e.id == id; });
        if (cacheResult.length === 0) {
            template = new t($('[data-template=' + id + ']').html().replace('<!--[', '').replace(']-->', ''));
            util.templateCache.push({ id: id, template: template });
        } else {
            template = cacheResult[0].template;
        }
        return $(template.render(data));
    },

    // filters input on a text box
    filterInput: function (ele, filter) {
        if (filter == "positiveInt") {
            filter = "[0-9]";
        } else if (filter === "positiveFloat") {
            filter = "[0-9\\.]";
        } else if (filter === "text") {
            filter = "[a-zA-Z ]";
        } else if (filter === "ext-text") {
            filter = "[a-zA-Z0-9 \\.-]";
        }
        $(ele).filter_input({ regex: filter });
    },

    // hyperbolic tangent approximation
    // taken from http://stackoverflow.com/questions/6118028/fast-hyperbolic-tangent-approximation-in-javascript (Andrew Hare answer)
    tanh: function(x) {
        return (Math.exp(x) - Math.exp(-x)) / (Math.exp(x) + Math.exp(-x));
    },

    /// Converts srm to appropriate Hex color
    srm_To_hex: function (srm) {
        var hex = ["#FFE699", "#FFD878", "#FFCA5A", "#FFBF42", "#FBB123", "#F8A600", "#F39C00", "#EA8F00", "#E58500", "#DE7C00", "#D77200", "#CF6900",
                    "#CB6200", "#C35900", "#BB5100", "#B54C00", "#B04500", "#A63E00", "#A13700", "#9B3200", "#952D00", "#8E2900", "#882300", "#821E00",
                    "#7B1A00", "#771900", "#701400", "#6A0E00", "#660D00", "#5E0B00", "#5A0A02", "#600903", "#520907", "#4C0505", "#470606", "#440607",
                    "#3F0708", "#3B0607", "#3A070B", "#36080A", "#000000"];

        srm = parseFloat(srm).toFixed(0);

        if (srm > 41) {
            return hex[hex.length - 1];
        } else {
            return hex[srm - 1];
        }
    },

    // conversion helper
    convert: function (selector, prevUnit, standardFunc, metricFunc, decPlaces) {
        if (!$(selector).length) {
            return;
        }
        if($(selector).is('span')) {
            if($(selector).text().length == 0) {
                return;
            }
            var value = (prevUnit == 's' ? metricFunc($(selector).text()) : standardFunc($(selector).text())).toFixed(decPlaces || 2);
            $(selector).text(value);
        } else {
            if ($(selector).val().length == 0) {
                return;
            }
            var value = (prevUnit == 's' ? metricFunc($(selector).val()) : standardFunc($(selector).val())).toFixed(decPlaces || 2);
            $(selector).val(value);
        }
    },

    /// Converts F to C
    f_To_c: function(f) {
        return util.safeRound((f - 32) * 5 / 9, 10);
    },

    /// Converts C to F
    c_To_f: function(c) {
        return util.safeRound(c * 9 / 5 + 32, 10);
    },

    /// Converts lbs to oz
    lb_To_oz: function (lb) {
        return lb * 16;
    },

    /// Converts oz to lbs
    oz_To_lb: function (oz) {
        return oz / 16;
    },

    /// Comverts oz to g
    oz_To_g: function (oz) {
        return oz * 28.3495;
    },

    /// Converts oz to kg
    oz_To_kg: function (oz) {
        return oz * .0283495;
    },

    /// Converts g to oz
    g_To_oz: function (g) {
        return g / 28.3495;
    },

    /// Converts kg to oz
    kg_To_oz: function (kg) {
        return kg / .0283495;
    },

    /// Converts kg to lbs
    kg_To_lb: function (kg) {
        return kg * 2.2046;
    },

    /// Converts lbs to kg
    lb_To_kg: function (lb) {
        return lb / 2.2046;
    },

    /// Converts ml to tsp
    ml_To_tsp: function (ml) {
        return ml * 0.202884;
    },

    /// Converts l to gal    
    l_To_gal: function (l) {
        return l * 0.264172;
    },

    /// Converts l to qt
    l_To_qt: function(l) {
        return l * 1.0567;
    },

    /// Converts gal to l
    gal_To_l: function (gal) {
        return gal / 0.264172;
    },

    /// Converts pt to l
    pt_To_l: function (pt) {
        return pt * 0.473176;
    },

    /// Converts qt to l
    qt_To_l: function (qt) {
        return qt * 0.946353;
    },

    /// Converts l to floz
    l_To_floz: function (l) {
        return l * 33.814;
    },

    /// Converts floz to l
    floz_To_ml: function (floz) {
        return floz * 29.5735;
    },

    /// Converts tbsp to ml
    tbsp_To_ml: function (tbsp) {
        return tbsp * 14.7868;
    },

    /// Converts tsp to ml
    tsp_To_ml: function (tsp) {
        return tsp * 4.92892;
    },

    /// Converts qt/lb to l/kg
    qt_per_lb_To_l_per_kg (qtPerLb) {
        return qtPerLb * 2.08635;
    },

    /// Converts l/kg to qt/lb
    l_per_kg_To_qt_per_lb (lPerKg) {
        return lPerKg * 0.47931;
    },

    /// Converts gal/lb to l/kg
    gal_per_lb_To_l_per_kg (galPerLb) {
        return galPerLb * 2.08635 * 4;
    },

    /// Converts l/kg to gal/lb
    l_per_kg_To_gal_per_lb (lPerKg) {
        return lPerKg * 0.47931 / 4;
    }
};