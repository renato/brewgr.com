// DOM Load Functionality
$(function () {
    general_onReady();
    layout_onReady();
    common_onReady();
    feedback_onReady();
    search_onReady();
    home_onReady();
    builder_onReady();
    settings_onReady();
    loginRelated_onReady();
    waterinfusion_onReady();
    recipeDetail_onReady();
    misc_onReady();
    comment_onReady();
    dashboard_onReady();
    calculations_onReady();
});

/* --------------------------------------------------- [ General ] ---------------------------------------------------------- */
function general_onReady() {
    // Preload Colorbox images
    $('<img src="/img/colorbox/border.png"/>');
    $('<img src="/img/colorbox/controls.png"/>');
    $('<img src="/img/colorbox/loading.gif"/>');
    $('<img src="/img/colorbox/loading_background.png"/>');
    $('<img src="/img/colorbox/overlay.png"/>');

    // Tipsy Tool Tips
    $('[original-title]').each(function (index, ele) {
        $(ele).tipsy({ gravity: 's' });
    });

    // Input Filters
    $('[data-filter]').each(function() {
        util.filterInput($(this), $(this).attr('data-filter'));
    });
    
    // Date Picker
    //$('.datepicker').datepicker();
    console.log("TODO: Replace datepicker with a non jqueryIU version");

    $('.recipe-import').click(function () {
        $.colorbox({ html: '<iframe id="ImportBeerXmlIFrame" src="/ImportBeerXmlDialog" width="525" height="200" scrolling="no" />', opacity: .35, overlayClose: false, escKey: false, scrolling: false });
        return false;
    });

    // Following Button Toggle
    $('[data-followid]').on('mouseover mouseout click', function (event) {
        var btn = $(this);
        var followed = $(this).data('followed') == "1";
        var id = $(this).data('followid');
        var textEle = $(this).children('span:nth-of-type(2)');
        var iconEle = $(this).children('span:first-of-type');

        if (event.type === 'mouseover') {
            if (followed) {
                btn.removeClass().addClass('btn btn-danger');
                iconEle.removeClass().addClass('glyphicon glyphicon-remove');
                textEle.text("Stop Following");
            } else {
                btn.removeClass().addClass('btn btn-success');
                iconEle.removeClass().addClass('glyphicon glyphicon-plus');
                textEle.text("Follow");
            }
        }
        else if (event.type === 'mouseout') {
            if (followed) {
                btn.removeClass().addClass('btn btn-success');
                iconEle.removeClass().addClass('glyphicon glyphicon-check');
                textEle.text("Following");
            } else {
                btn.removeClass().addClass('btn btn-default');
                iconEle.removeClass().addClass('glyphicon glyphicon-plus');
                textEle.text("Follow");
            }
        } else if(event.type === 'click') {
            event.preventDefault();
            btn.attr('disabled', 'disabled');
            $.ajax({
                url: '/api/user/relation/' + id,
                async: true,
                type: followed ? "delete" : "post",
                success: function (t) {
                    if (followed) {
                        textEle.text("Follow");
                        btn.removeClass().addClass('btn btn-default');
                        iconEle.removeClass().addClass('glyphicon glyphicon-plus');
                        btn.data('followed', '0');
                    } else {
                        textEle.text("Following");
                        btn.removeClass().addClass('btn btn-success');
                        iconEle.removeClass().addClass('glyphicon glyphicon-check');
                        btn.data('followed', '1');
                    }
                },
                error: function () {
                    alert("uh oh, something went wrong.  Please try again.");
                },
                complete: function() {
                    btn.removeAttr('disabled');
                }
            });
        }

    });

    // Login Links (return Url)
    $('.login-link').click(function() {
        var url = window.location.toString();
        if (url.indexOf('/login') == -1) {
            if (url.substring(url.indexOf('/')) != "login") {
                $(this).attr('href', $(this).attr('href') + '?ReturnUrl=' + $(this).attr('data-returnurl'));
            }
        }
    });
    
    // Sign Out Link (go back to where you were)
    $('.sign-out-link').click(function() {
        $(this).attr('href', $(this).attr('href') + '?ReturnUrl=' + $(this).attr('data-returnurl'));
    });

    $("#calculations[data-showinmodal=1]").click(function () {
        $.colorbox({ href: $(this).attr('href') + '?iframe=1', iframe: true, width: 850, height: 525, opacity: .35, overlayClose: false, escKey: false, scrolling: true });
        return false;
    });

    // Tasting Notes Autosize
    $('#tasting-note-form .notes textarea').autosize();

    // Tasting Notes Submission
    $('#tasting-note-form .save a').click(function () {

        // Clear previous messages
        $('#tasting-note-form').find('.messages').remove();

        // Validate
        if (!$('#tasting-note-form #taste-date').val().length || !$('#tasting-note-form #Rating').val().length)
        {
            $('#tasting-note-form').prepend($('<div class="messages small"><ul><li class="error">Date Tasted and Overall Rating are required</li></ul></div>'));
            return false;
        }

        var payload = {
            RecipeId: $('#TastingNotesRecipeId').val(),
            BrewSessionId: $('#TastingNotesBrewSessionId').val(),
            TasteDate: $('#taste-date').val(),
            Rating: $('#tasting-note-form #Rating').val(),
            Notes: $('#tasting-note-form .notes textarea').val()
        };

        var modalComplete = function () {
            $.ajax({
                url: "/brew/SaveTastingNote",
                data: payload,
                method: "post",
                success: function (t) {
                    switch (t) {
                        case "-1": // general failure
                            $('#tasting-note-form').prepend($('<div class="messages small"><ul><li class="error">An unknown error has occurred.  Please try again</li></ul></div>'));
                            break;
                        case "0": // validation error
                            $('#tasting-note-form').prepend($('<div class="messages small"><ul><li class="error">Date Tasted and Overall Rating are required</li></ul></div>'));
                            break;
                        default: // success
                            var result = $(t);

                            $('.no-tasting-notes').remove();

                            $('.tasting-notes').append(result);
                            wireRatyStar(result.find('span.rating[data-rating]'));

                            // Increment Count
                            var count = parseInt($('#tasting-note-count').html());
                            $('#tasting-note-count').html(++count);

                            // Reset Form
                            setupRatyStar('#star');
                            $('#tasting-note-form .notes textarea').val('');
                            var date = new Date();
                            $('#taste-date').val((date.getMonth() + 1) + "/" + date.getDate() + "/" + date.getFullYear());
                            break;
                    }
                },
                error: function (t) {
                    Message.error('There was a problem saving your brew session.  Please try again.');
                },
                complete: function() {
                    $.colorbox.close();
                }
            });
        };

        Layout.statusModal('Saving Tasting Notes...', modalComplete);
        return false;
    });

    // Launch links in new window
    $('a.new-window').click(function () {
        window.open($(this).attr('href'));
        return false;
    });

    // Back To Top Button
    var pxShow = 300;//height on which the button will show
    var fadeInTime = 400;//how slow/fast you want the button to show
    var fadeOutTime = 400;//how slow/fast you want the button to hide
    var scrollSpeed = 400;//how slow/fast you want the button to scroll to top. can be a value, 'slow', 'normal' or 'fast'

    jQuery(window).scroll(function () {
        if (jQuery(window).scrollTop() >= pxShow) {
            jQuery("#backtotop").fadeIn(fadeInTime);
        } else {
            jQuery("#backtotop").fadeOut(fadeOutTime);
        }
    });

    jQuery('#backtotop a').click(function () {
        jQuery('html, body').animate({ scrollTop: 0 }, scrollSpeed);
        return false;
    });


    //////////////////////////////////////////

    // Time Ago
    $("abbr.timeago").timeago().show();

    // Raty
    $('[data-rating]').raty({
        path: '/img/raty/',
        hints: ['worst beer ever', 'ok', 'good', 'really good', 'best beer ever'],
        readOnly: function() { return $(this).data('readonly'); },
        score: function() { return $(this).data('rating'); }
    });
}

/* --------------------------------------------------- [ Layout ] ---------------------------------------------------------- */
function layout_onReady() {
 // Email Signup
    $('#newsletterform').submit(function () {
        $.ajax($(this).attr("action") + '/?emailAddress=' + $('#newsletterform input:first').val(),
			{
			    async: true,
			    cache: false,
			    success: function (t) {
			        $.colorbox({ html: '<h1 class="aligncenter">Thank you for signing up!</h1>', opacity: .35, width: 500, height: 70, scrolling: false });
			        $('#newsletterform input:first').val('Enter your email adress').trigger('blur');
			    }
			});
        return false;
    });

    // Recent Recipe Photos
    if ($('footer .photo-stream').length > 0) {
        $.ajax({
            url: '/RecentPhotos',
            success: function(t) {
                $(t).each(function(i, e) {
                    $('footer .photo-stream')
                        .append($('<a href="' + e.Url + '"><img width="59" height="59" alt="" src="' + e.ImageUrl + '" /></a>'));
                });
            }
        });
    }

    // Mobile Menu - Hamburger Toggle
    $('#mobilemenu button.menu').click(function (event) {
        event.preventDefault();
        $('#navigation').toggle();
    });

    // Search Menu Trigger
    $('.searchtrig').click(function () {
        $('#navigation').hide();
        $('html, body').animate({ scrollTop: 0 }, 'fast');
        $('#search').slideDown();
        $('#SearchTerm').focus();
    });

    $(window).scroll(function() {
        if($('#hamburger a.menu').is(':visible')) {
            $('#navigation').hide();
        }
    });

    // see: https://css-tricks.com/dangers-stopping-event-propagation/
    $(document).on('click', function (event) {
        if ($(event.target).closest('#navigation').length) {
            if($('.mobile a.menu').is(':visible')) {
                $('#navigation').toggle();
            }
        }
    });
}



/* --------------------------------------------------- [ Common ] ---------------------------------------------------------- */
function common_onReady() {
    $('body').on('click', '.delete-brewsession', function (e) {
        $.colorbox({ html: '<div style="padding: 12px 24px 0 24px;"><h3>Are you sure you want to delete this?</h3><p>Once you delete a brew session there is no way to get it back.<br /><a class="button button_black marginleft20 margintop10" href="/brew/' + $(this).attr("data-brewsessionid") + '/delete">Yes, Delete</a><a class="button button_black marginleft20 margintop10" href="#" onclick="$.colorbox.close()">No, don\'t delete</a><p/></div>', opacity: .35, overlayClose: false, escKey: false, scrolling: false });
        return false;
    });
    
    $('body').on('click', '.delete-recipe', function (e) {
        $.colorbox({ html: '<div style="padding: 12px 24px 0 24px;"><h3>Are you sure you want to delete this?</h3><p>Once you delete a recipe there is no way to get it back.<br /><a class="button button_black marginleft20 margintop10" href="/recipe/' + $(this).attr("data-recipeid") + '/delete">Yes, Delete</a><a class="button button_black marginleft20 margintop10" href="#" onclick="$.colorbox.close()">No, don\'t delete</a><p/></div>', opacity: .35, overlayClose: false, escKey: false, scrolling: false });
        return false;
    });

    // Existing Rating Stars
    if ($('span.rating[data-rating]').length > 0) {
        $('span.rating[data-rating]').each(function (i, e) {
            wireRatyStar(e);
        });
    }

    // Delete Tasting Notes
    $('#tastingnotes').on('click', 'a[data-tastingnoteid]', function () {
        $.colorbox({ html: '<div style="padding: 12px 24px 0 24px;"><h3>Are you sure you want to delete this?</h3><p>Once you delete tasting notes there is no way to get them back.<br /><a class="button button_black marginleft20 margintop10" href="#" onclick="deleteTastingNote(' + $(this).attr("data-tastingnoteid") + '); $.colorbox.close(); return false;">Yes, Delete</a><a class="button button_black marginleft20 margintop10" href="#" onclick="$.colorbox.close(); return false;">No, don\'t delete</a><p/></div>', opacity: .35, overlayClose: false, escKey: false, scrolling: false });
        return false;
    });

    // New Rating Stars (dynamic)
    setupRatyStar($('#star'));
}
/* --------------------------------------------------- [ Feedback ] ---------------------------------------------------------- */
function feedback_onReady() {
    // Feedback Dialog (dont show on smaller resolutions)
    if ($(window).width() > 1050) {
        $('#FeedbackTrigger').show().click(function() {
            $.colorbox({ html: '<iframe id="ImportBeerXmlIFrame" src="/marketing/feedback" width="650" height="330" scrolling="no" />', opacity: .35, overlayClose: false, escKey: true, scrolling: false });
            return false;
        });
    }
    
    if ($('#Feedback').length > 0) {
        $('#Feedback').limitInput(1000, $('#FeedbackCounter'), true);
        
        $('#suggestion-form a')
        .click(function () {
            $.ajax({
                url: '/Marketing/Feedback',
                type: 'post',
                data: { Feedback: $('#suggestion-form textarea').val() },
                success: function () {
                    $('#suggestion-form .success-message').show();
                    $('#suggestion-form textarea').val('');
                    $('#suggestion-form textarea').trigger('keyup');
                }
            });
            return false;
        });
    }

    $('#suggestion-form textarea').keypress(function () {
        if ($('#suggestion-form .success-message').is(':visible')) {
            $('#suggestion-form .success-message').hide();
        }
    });

    if ($('#view-feedback').length > 0) {        
        $('#Feedback').keypress(function () {
                if ($(this).hasClass('input-validation-error') && $(this).val()) {
                    $(this).removeClass('input-validation-error');
                }
            });

        // Feedback Form Validation
        $('#view-feedback form').submit(function() {
            if (!$('#Feedback').val()) {
                $('#Feedback').addClass('input-validation-error');
                return false;
            }
            return true;
        });
    }
    
    if ($('#view-feedbackreceived').length > 0) {
        parent.$.colorbox.resize({ width: 650, height: 200 });
        $('#FeedbackClose').click(function() {
            parent.$.colorbox.close();
            return false;
        });
    }
}

function search_onReady() {
    if ($('#searchresults-view').length > 0) {
        
        // Selects the appropriate tab by default
        var tabs = $('li[role=tab]');
        for (var i = 0; i < tabs.length; i++) {
            if(parseInt($(tabs[i]).attr('data-count')) > 0)
            {
                if(i == 0) break;
                $(tabs[i]).find('a').click();
                break;
            }
        }
    } 
}

/* --------------------------------------------------- [ Home ] ---------------------------------------------------------- */
function home_onReady() {
    if ($('#fb-root').length > 0) {
        (function (d, s, id) {
            var js, fjs = d.getElementsByTagName(s)[0];
            if (d.getElementById(id)) return;
            js = d.createElement(s);
            js.id = id;
            js.src = "//connect.facebook.net/en_US/all.js#xfbml=1&appId=324420670945545";
            fjs.parentNode.insertBefore(js, fjs);
        }(document, 'script', 'facebook-jssdk'));
    }
}

/* --------------------------------------------------- [ Builder ] ---------------------------------------------------------- */
function builder_onReady() {

    if ($('#view-newrecipe, #view-editrecipe, #view-recipedetail').length > 0) {

        // Style Guide
        $('[data-name=styleid]').change(function () {
            var recipe = getRecipe();
            if ($(this).val() == '') {
                $('#recipe-facts .style').text('');
                $('#selected-style-chart').empty();
            } else {
                $('#recipe-facts .style').text($(this[this.selectedIndex]).text().split('. ')[1]);

                // set up the style chart
                var targetStyle = StyleChart.GetStyle($(this[this.selectedIndex]).val());
                $('#selected-style-chart').empty();
                StyleChart.create(targetStyle, recipe, $('#selected-style-chart'));
            }
        });

        $('#show-similar-styles').click(function () {
            var recipe = getRecipe();
            var allStylesSorted = StyleChart.SortStylesByClosestMatch(recipe);
            var numberOfResults = (StyleChart.isWater(recipe)) ? 1 : 3;
            for (var i = 0; i < numberOfResults; i++) {
                StyleChart.create(allStylesSorted[i], recipe, $('#similar-style-chart'));
            }
            $('#style-showmore').hide();
            $('#style-hidemore').show();
            return false;
        });

        $('#hide-similar-styles').click(function() {
            $('#similar-style-chart').empty();
            $('#style-showmore').show();
            $('#style-hidemore').hide();
            return false;
        });
    }
    
    if ($('#view-newrecipe, #view-editrecipe, #view-newbrewsession, #view-editbrewsession').length > 0) {
        // Make the Recipe Facts Box Move While Scrolling
        function isScrolledTo(elem) {
            var docViewTop = $(window).scrollTop(); //num of pixels hidden above current screen
            //var docViewBottom = docViewTop + $(window).height();
            var elemTop = $(elem).offset().top; //num of pixels above the elem
            //var elemBottom = elemTop + $(elem).height();
            return ((elemTop <= docViewTop || elemTop >= docViewTop));
        }

        var catcher = $('.catcher');
        var sticky = $('.builder-wrapper .compliment');
        //var lastStickyTop = sticky.offset().top;

        $(window).scroll(function () {

            var footer = $('#footer');
            var footTop = footer.offset().top -24;

            sticky.css('margin-left', '700px');

            if(isScrolledTo(sticky)) {
                sticky.css('position','fixed');
                sticky.css('top','10px');
            }
            var stopHeight = catcher.offset().top + catcher.height();
            var stickyFoot = sticky.offset().top + sticky.height();
       
            if(stickyFoot > footTop -10){
                sticky.css({
                    position:'absolute',
                    top: (footTop - 20) - sticky.height()
                });
            } else {
                if ( stopHeight > sticky.offset().top) {
                    sticky.css('position','absolute');
                    sticky.css('top',stopHeight);
                }
            }
        });

        // Track Form Changes
        $('.builder input, .builder select, .builder textarea').not('#taste-date').not('#NewTastingNotes').not('.CommentText').change(function () {
            if (!$('.builder').attr('data-formchanged')) {
                $('.builder').attr('data-formchanged', 'true');
            }
        });

        // Warn of Lost Changes
        $(window).bind('beforeunload', function() {
            if ($('.builder[data-formchanged=true]').length > 0) {
                return 'You have unsaved changes';
            }
        });
        
        // Delete Recipe Event
        $(".delete-recipe").click(function(e) {
            var currentElem = $(this);
            $.colorbox({ html: '<h3>Are you sure you want to delete this?</h3><p>Once you delete a recipe there is no way to get it back.<br /><a class="button button_black marginleft20 margintop10" onclick="$(\'.builder\').removeAttr(\'data-formchanged\');" href="/recipe/' + $(this).attr("data-recipeid") + '/delete">Yes, Delete</a><a class="button button_black marginleft20 margintop10" href="#" onclick="$.colorbox.close(); return false;">No, don\'t delete</a><p/>', opacity: .35, overlayClose: false, escKey: false, scrolling: false });
            return false;
        });
    }

    $('#sendtoshop-intro h3 a').click(function () {
        $.colorbox({ inline: true, href: '#sendtoshop-learnmore', opacity: .35, width: 700, height: 400, overlayClose: true, escKey: true, scrolling: false });
        return false;
    });
}

/// Gets an instance of Recipe, either for builder or detail
function getRecipe() {
    if ($('#RecipeJson').length > 0) {
        var parsedRecipe = new Recipe(jQuery.parseJSON($('#RecipeJson').text()));
        parsedRecipe.calculate();
        return parsedRecipe;
    } else {
        return Builder.getRecipe();
    }
}

/// Photo upload in progress callback
function photoUploadInProgress() {
    parent.$.colorbox.resize({ width: 800, height: 145 });
}

/// Photo upload complete callback
function photoUploadComplete() {
    var autoCloseTimeout = window.setTimeout(function () { $.colorbox.close(); }, 10000);
    $(document).bind('cbox_closed', function () { window.clearTimeout(autoCloseTimeout); });
}

/* --------------------------------------------------- [ Recipe Detail ] ---------------------------------------------------------- */
function recipeDetail_onReady() {
    if ($('#view-recipedetail').length > 0) {

        // Rating
        $('#recipe-rating').raty({
            path: '/img/raty/',
            hints: ['worst beer ever', 'ok', 'good', 'really good', 'best beer ever'],
            readOnly: true,
            score: $('#recipe-rating').attr('data-rating')
        });
        
        $('#CommentText').autosize();
    }
}


/* --------------------------------------------------- [ Settings ] ---------------------------------------------------------- */
function settings_onReady() {
    if ($('#view-settings').length > 0) {
        var usernameTimer = null;
        var emailTimer = null;

        $('#view-settings .tabs').tabs({
            beforeActivate: function() {
                Message.clear();
            }
        });

        if (window.location.toString().indexOf("#notifications") > -1) {
            $('li#tab3 > a').click();
        };

        Message.useSmall();
        Message.setParent($('#view-settings form').parents('.tab'));

        $('#view-settings form').ajaxForm({
            preSubmitCallback: function (theForm) {
                Message.clear();                
            },
            successCallback: function (theForm, data) {
                if(!data.Success && data.Message) {
                    Message.error(data.Message);
                } else {
                    Message.success(data.Message);
                }

                window.scrollTo(0, 0);
            },
            errorCallback: function (theForm) {
                Message.error("Oops, something went wrong.  Please try again.");
                window.scrollTo(0, 0);
            }
        });

        $('#view-settings .username').keyup(function() {

            clearTimeout(usernameTimer);

            $(this).removeClass('input-validation-error');

            if ($(this).val().length < 3) {
                $('#username-avail').text('');
                return true;
            }

            var username = $(this).val();

            usernameTimer = setTimeout(function() {
                // Check if Username Exists
                $.ajax("UsernameExists/" + username.trim() + "?d=" + new Date(),
                    {
                        success: function(r) {
                            if (r == "1") {
                                $('#username-avail').text("username taken").css('color', 'red');
                                $('#Username').addClass('input-validation-error');
                                $('#savesettings').attr('disabled', 'disabled');
                                $('#Dummy').val('');
                            } else {
                                $('#username-avail').text("username available").css('color', 'green');
                                $('#Username').removeClass('input-validation-error');
                                $('#Dummy').val('value');
                                $('#savesettings').removeAttr('disabled');
                            }
                        }
                    });
            }, 350);
        });

        $('#view-settings .emailaddress').keyup(function() {

            clearTimeout(emailTimer);

            var emailAddress = encodeURIComponent($(this).val());

            emailTimer = setTimeout(function() {
                $.ajax("EmailAddressInUse/?email=" + emailAddress.trim() + "&d=" + new Date(),
                    {
                        success: function(r) {
                            if (r == "1") {
                                $('#emailinuse').text("Email Address already in use").css('color', 'red').show();
                                $('#EmailAddress').addClass('input-validation-error');
                                $('#savesettings').attr('disabled', 'disabled');
                                $('#Dummy').val('');
                            } else {
                                $('#emailinuse').hide();
                                $('#EmailAddress').removeClass('input-validation-error');
                                $('#Dummy').val('value');
                                $('#savesettings').removeAttr('disabled');
                            }
                        }
                    });
            }, 350);
        });

        $('#ChooseUsername').click(function() {
            $('#UsernameFieldToggle').remove();
            $('#Username').val('');
            $('label[for=Username]').addClass('valigntop').addClass('paddingtop6');
            $('#UsernameField').removeClass('hidden').slideDown();
            $('#Username').focus();
        });

        $('#Bio').limitInput(450, $('#suggest-limit'), true);
    }
}

/* --------------------------------------------------- [ Login Related ] ---------------------------------------------------------- */

function loginRelated_onReady() {

    // Resize Colorbox for Reset Password
    if ($('#view-resetpassword.is-in-dialog').length) {
        var height = $('.messages').is(':visible') ? 375 : 280;
        parent.$.colorbox.resize({ width: 650, height: height });
    }
    
    // Ensure Colorbox Size on LoginViaDialog
    if ($('#view-loginviadialog').length) {
        parent.$.colorbox.resize({ width: 800, height: 525 });
    }
}

function loginComplete(editMode) {
    $('.builder').removeAttr('data-isanon');
    parent.$.colorbox.resize({ width: 800, height: 150 });

    if(editMode) {
        window.setTimeout(function () { $('#SaveRecipeButton').click(); }, 2000);
    } else {
        $('#RecipeJson').val(escape(Builder.getRecipe().getJSON()));
        $('#RecipeForm').submit();
    }

    
}

/* --------------------------------------------------- [ Water Infusion ] ---------------------------------------------------------- */
function waterinfusion_onReady() {
    if ($('#view-calculatorHydro').length > 0) {
        
         $('.optional-equipment-expand').toggle(
            function () {
                $('.optional-equipment-expand img').attr('src', '/img/less-up-arrow.png');
                $('.optional-equipment').show();
            },
            function () {
                $('.optional-equipment-expand img').attr('src', '/img/more-down-arrow.png');
                $('.optional-equipment').hide();
            }
        );
        
    }
}

/* --------------------------------------------------- [ Miscellaneous ] ---------------------------------------------------------- */
function misc_onReady() {
    // Import Recipe Form Validation (built-in validation doesnt work with file upload)
    $('input#BeerXmlFile').change(function() {
        $('input#BeerXmlFile').removeClass('input-validation-error');
    });
    $('#ImportRecipeForm').submit(function () {
        $('input#BeerXmlFile').removeClass('input-validation-error');
        if ($('input#BeerXmlFile').val().length == 0) {
            $('input#BeerXmlFile').addClass('input-validation-error');
            return false;
        }
        return true;
    });

    // Set Facts Color 
    if ($('.facts .color').length > 0 && $('[data-name=facts_srm]').length > 0) {
        $('.facts .color').css('background-color', util.srm_To_hex($('[data-name=facts_srm]').text()));
    }
}

/* --------------------------------------------------- [ Brew Sessions ] ---------------------------------------------------------- */


/* --------------------------------------------------- [ Mash Sparge Infussion Calculator ] ---------------------------------------------------------- */
var WaterCalc =
{
    // init
    initialize: function(inputElement, outputElement, unitElement) {

        $('[data-unit="' + $('[data-name=s_UnitType]').val() + '"]').addClass('active');

        this.inputElement = inputElement;
        this.outputElement = outputElement;
        this.unitElement = unitElement;

        this.wireCalcTriggers();
        this.calculate();

        return this;
    },

    useUnit: function(unit) {
        if ($('[data-name=s_UnitType]') === unit) {
            return;
        }

        var prevUnit = unit === 'm' ? 's' : 'm';

        // Toggle Labels
        $('[data-unit].active').removeClass('active');
        $('[data-unit="' + unit + '"]').addClass('active');

        util.convert('[data-name=s_GrainWeight]', prevUnit, util.kg_To_lb, util.lb_To_kg);
        util.convert('[data-name=s_GrainTemp]', prevUnit, util.c_To_f, util.f_To_c);
        util.convert('[data-name=s_FermentVolume]', prevUnit, util.l_To_gal, util.gal_To_l);
        util.convert('[data-name=s_TargetMashTemp]', prevUnit, util.c_To_f, util.f_To_c);
        util.convert('[data-name=s_MashThickness]', prevUnit, util.l_To_qt, util.qt_To_l);

        util.convert('[data-name=s_BrewKettleLoss]', prevUnit, util.l_To_gal, util.gal_To_l);
        util.convert('[data-name=s_WortShrinkage]', prevUnit, util.l_To_gal, util.gal_To_l);
        util.convert('[data-name=s_MashTunLoss]', prevUnit, util.l_To_gal, util.gal_To_l);
        util.convert('[data-name=s_BoilLoss]', prevUnit, util.l_To_gal, util.gal_To_l);
        util.convert('[data-name=s_MashGrainAbsorption]', prevUnit, util.l_To_gal, util.gal_To_l);
        util.convert('[data-name=s_SpargeGrainAbsorption]', prevUnit, util.l_To_gal, util.gal_To_l);

        $('[data-name=s_GrainWeight]').keyup(); // force re-calc (the easy way)
    },

    // Does the calculation
    calculate: function () {

        var input = {
            grain: this.getValue('.wc_grain', util.kg_To_lb),
            fermentVol: this.getValue('.wc_fermentVol', util.l_To_gal),
            kettleLoss: this.getValue('.wc_kettleLoss', util.l_To_gal),
            wortShrinkage: this.getValue('.wc_wortShrinkage', util.l_To_gal),
            boilTime: this.getValue('.wc_boilTime'),
            boilLoss: this.getValue('.wc_boilLoss', util.l_To_gal),
            mashThickness: this.getValue('.wc_mashThickness', util.l_To_qt),
            mashTunLoss: this.getValue('.wc_mashTunLoss', util.l_To_gal),
            mashAbsorp: this.getValue('.wc_grainAbsorption', util.l_To_gal),
            spargeAbsorp: this.getValue('.wc_spargeGrainAbsorption', util.l_To_gal),
            mashTemp: this.getValue('.wc_targetMashTemp', util.c_To_f),
            grainTemp: this.getValue('.wc_grainTemp', util.c_To_f)
        };

        // Total Runoff
        var runoffVol = (input.fermentVol + input.kettleLoss + input.wortShrinkage) + (input.boilTime * input.boilLoss / 60);
        this.setValue('.wc_runoff', util.gal_To_l, runoffVol);

        // Mash Strike Volume
        var mashStrikeVol = ((input.mashThickness * input.grain) / 4) + input.mashTunLoss;
        this.setValue('.wc_strikeVol', util.gal_To_l, mashStrikeVol);

        // First Runnings 
        var firstRunnings = mashStrikeVol - (input.grain) * input.mashAbsorp;
        this.setValue('.wc_firstRunnings', util.gal_To_l, firstRunnings);

        // Sparge Volume
        var spargeVol = (runoffVol - firstRunnings) + (input.spargeAbsorp * input.grain);
        this.setValue('.wc_spargeVol', util.gal_To_l, spargeVol);

        // Strike Temp
        this.setValue('.wc_strikeTemp', util.f_To_c, ((((input.grain * .05) + mashStrikeVol) * input.mashTemp) - ((input.grain * .05) * input.grainTemp)) / mashStrikeVol);

        // Total Water Needed
        this.setValue('.wc_totalWater', util.gal_To_l, mashStrikeVol + spargeVol);
    },

    // Wires Calc Triggers
    wireCalcTriggers: function () {
        var outer = this;
        this.inputElement.find('.wc_trig').keyup(function () {
            outer.calculate();
        });
    },

    // Fetches an input value, standardizing to US units
    getValue: function (selector, convFunc) {
        var value = tryNumber($(this.inputElement).find(selector).val());
        return this.unitElement.val() == 'm' ? (convFunc != null ? convFunc(value) : value) : value;
    },

    // Sets a value
    setValue: function(selector, convFunc, val) {
        var value = this.unitElement.val() == 'm' ? convFunc(val) : val;
        this.outputElement.find(selector).val(value.toFixed(2));
    }
};

/* --------------------------------------------------- [ Comment ] ---------------------------------------------------------- */
function comment_onReady() {
    
    if ($('.comments-wrapper').length > 0) {

        jQuery("abbr.timeago").timeago();
        $("abbr.timeago").timeago().show();

        $('.CommentText').autosize();
        
        $('body').on('keydown', '.CommentText', function (e) {
            if (e.which == 13) {
                e.preventDefault();
                $(this).next('#AddComment').click();
            }
        });

        $('body').on('click', '.AddComment', function (e) {
            if (!$(this).parent().prev('.CommentText').val() || $.trim($(this).parent().prev('.CommentText').val()).length == 0 || $.trim($(this).parent().prev('.CommentText').val()) == 'Write a comment...') {
                return false;
            }

            var self = $(this);

            $.ajax({
                url: '/AddComment',
                type: 'post',
                data: { CommentText: $('<div/>').text(self.parent().prev('.CommentText').val()).html(), GenericId: $(this).attr('data-genericid'), CommentType: $(this).attr('data-commenttype') },
                success: function (response) {
                    self.closest('.comments-wrapper').find('.comment-list').append(response);

                    // Recreate autosize to re-adjust size after clearing
                    // Required a modification to the autosize.js library
                    // Could not upgrade at this time -- it is EMCA6 and gets bundled
                    // with all of the JS -- would have to extract and not worth the effort at this time
                    self.parent().prev('.CommentText').val('').autosize();

                    jQuery("abbr.timeago").timeago();
                    $("abbr.timeago").timeago().show();
                    return false;
                }
            });
            return false;
        });
    }
}


function calculations_onReady() {
    if($('.calculations#water-calc').length) {
        WaterCalc.initialize($('#s_waterIn'), $('#s_waterOut'), $('select[data-name=s_UnitType]'));

        $('select[data-name=s_UnitType]').change(function() {
            WaterCalc.useUnit($(this).val());
        });
    }
}

/* --------------------------------------------------- [ Dashboard ] ---------------------------------------------------------- */
function dashboard_onReady() {
    if ($('#dashboard').length > 0) {
        
        function getFormattedPartTime(partTime) {
            if (partTime < 10)
                return "0" + partTime;
            return partTime;
        }

        function getDefaultDateForDashboard () {
            var d = new Date();
            return d.getFullYear() + '' + getFormattedPartTime(d.getMonth()) + '' + getFormattedPartTime(d.getDate());
        }

        $.ajax({
            url: '/dashboard/all',
            type: 'get',
            success: function (response) {
                $('#tabfeed').html(response);
                $('[data-rating]').each(function(i, e) { wireRatyStar(e); });
                comment_onReady();
            }
        });

        $('body').on('click', '.dashboard-more', function (e) {
            var dateoflast = $(this).attr('data-dateoflast');
            var numberToReturn = $(this).attr('data-numbertoreturn');
            $(this).replaceWith('<img src="/img/ajax-spinner.gif" class="dashboard-morespinner" />');
            $.ajax({
                url: '/dashboard/all/' + numberToReturn + '/?SearchOlderThan=' + dateoflast,
                type: 'get',
                success: function (response) {
                    $('.dashboard-morespinner').hide();
                    $('#dashboardlist-moreplaceholder').replaceWith(response);
                    $('[data-rating]').each(function (i, e) { wireRatyStar(e); });
                    jQuery("abbr.timeago").timeago();
                    $("abbr.timeago").timeago().show();
                    return false;
                }
            });
            return false;
        });


        $('[aria-controls=tabrecipes]').click(function () {
            $('.dashboard-nomorerecipes').hide();
            $('.dashboard-nomorebrewsessions').hide();
            $.ajax({
                url: '/dashboard/recipes',
                type: 'get',
                success: function(response) {
                    $('#tabrecipes').html(response);
                    if (response.indexOf('NoDashboardItems') > 0) {
                        $('.dashboard-nomore').hide();
                        $('.dashboard-nomorerecipes').show();
                    }

                    $('#tab-tab-2 .CommentText').autosize();

                    $('.spinner-recipe .dashboard-more').hide();
                    jQuery("abbr.timeago").timeago();
                    $("abbr.timeago").timeago().show();
                    return false;
                }
            });
        });

        $('[aria-controls=tabsessions]').click(function () {
            $('.dashboard-nomorerecipes').hide();
            $('.dashboard-nomorebrewsessions').hide();
            $.ajax({
                url: '/dashboard/sessions',
                type: 'get',
                success: function(response) {
                    $('#tabsessions').html(response);
                    if (response.indexOf('NoDashboardItems') > 0) {
                        $('.dashboard-nomore').hide();
                        //$('.dashboard-nomorebrewsessions').removeClass("hidden");
                        $('.dashboard-nomorebrewsessions').show();
                    }

                    $('#tabrecipes .CommentText').autosize();

                    $('#tabrecipes .dashboard-more').hide();
                    jQuery("abbr.timeago").timeago();
                    $("abbr.timeago").timeago().show();
                    return false;
                }
            });
        });

        // Has Change Event
        $(window).on('hashchange', function () {
            handleDashboardHash();
        });

        // We call this (even if window.location.has is undefined)
        // Firefox doesn't define window.location.hash
        handleDashboardHash();
    }
}

// Handles Dashboard Hash Changes
function handleDashboardHash() {
    if (window.location.toString().indexOf("#recipes") > -1) {
        $('#tab-my-recipes').click();
    }

    if (window.location.toString().indexOf("#brewsessions") > -1) {
        $('#tab-my-brewsessions').click();
    }
}

/* --------------------------------------------------- [ Common Functions ] ---------------------------------------------------------- */
function tryNumber(input, defaultValue) {
    return isNaN(input) ? (defaultValue || 0) : Number(input);
}

function setupRatyStar(element) {
    $(element).raty({
        path: '/img/raty/',
        hints: ['worst beer ever', 'ok', 'good', 'really good', 'best beer ever'],
        target: '#Rating',
        targetType: 'number',
        targetKeep: true
    });
}

function wireRatyStar(element) {
    $(element).raty({
        path: '/img/raty/',
        hints: ['worst beer ever', 'ok', 'good', 'really good', 'best beer ever'],
        readOnly: true,
        score: $(element).attr('data-rating')
    });
}

function deleteTastingNote(tastingNoteId) {
    $.ajax({
        url: '/brew/DeleteTastingNote/' + tastingNoteId,
        type: 'post',
        async: true,
        success: function () {

            $('a[data-tastingnoteid=' + tastingNoteId + ']').parents('.tasting-note').remove();
            
            // Set Count
            var count = parseInt($('#tasting-note-count').html());
            $('#tasting-note-count').html(--count);

            if (count == 0) {
                $('.no-tasting-notes').remove();
                $('.tasting-notes-wrapper').append('<div class="no-tasting-notes padding10">There aren\'t any tasting notes logged yet</div>');
            }
        },
        error: function () {
            $('a[data-tastingnoteid=' + tastingNoteId + ']').parents('.tasting-notes').find('.messages').remove();
            $('a[data-tastingnoteid=' + tastingNoteId + ']').parents('.tasting-notes').prepend($('<div class="messages small"><ul><li class="error">Oops, something went wrong.  Please try again.</li></ul></div>'));
        }
    });
}

/* --------------------------------------------------- [ Browser Compatibility ] ---------------------------------------------------------- */
// Adds trim() function for older browsers like IE8
if (typeof String.prototype.trim !== 'function') {
    String.prototype.trim = function() {
        return this.replace(/^\s+|\s+$/g, '');
    };
}

