using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Runtime.Remoting.Metadata.W3cXsd2001;
using System.Web.Caching;
using ctorx.Core.Collections;
using Brewgr.Web.Core.Data;
using Brewgr.Web.Core.Model;
using ctorx.Core.Data;
using System.Threading.Tasks;
using ctorx.Core.Linq;
using System.Data;

namespace Brewgr.Web.Core.Service
{
	public class DefaultRecipeService : IRecipeService
	{
		readonly IBrewgrRepository Repository;
		readonly ICachingService CachingService;
		readonly IUserResolver UserResolver;
		readonly IRecipeDataService RecipeDataService;
		readonly IBeerStyleService BeerStyleService;
		readonly IPartnerIdResolver PartnerIdResolver;
		readonly IPartnerService PartnerService;
		readonly IIngredientCategorizer IngredientCategorizer;
		readonly IDataContextActivationInfo<BrewgrContext> DataContextActivationInfo;
		readonly IUserService UserService;
		readonly ISendToShopService SendToShopService;

		/// <summary>
		/// ctor the Mighty
		/// </summary>
        public DefaultRecipeService(IBrewgrRepository repository, ICachingService cachingService, IUserResolver userResolver, 
			IRecipeDataService recipeDataService, IBeerStyleService beerStyleService, IPartnerIdResolver partnerIdResolver, IPartnerService partnerService, 
			IIngredientCategorizer ingredientCategorizer, IDataContextActivationInfo<BrewgrContext> dataContextActivationInfo, IUserService userService,
			ISendToShopService sendToShopService)
		{
			this.Repository = repository;
			this.CachingService = cachingService;
			this.UserResolver = userResolver;
			this.RecipeDataService = recipeDataService;
			this.BeerStyleService = beerStyleService;
			this.PartnerIdResolver = partnerIdResolver;
			this.PartnerService = partnerService;
			this.IngredientCategorizer = ingredientCategorizer;
			this.DataContextActivationInfo = dataContextActivationInfo;
			this.UserService = userService;
			this.SendToShopService = sendToShopService;
		}

		/// <summary>
		/// Gets a recipe by Id
		/// </summary>
		public Recipe GetRecipeById(int recipeId)
		{
			if (recipeId <= 0)
			{
				throw new ArgumentOutOfRangeException("recipeId");
			}

			// Grab Current User Id, if any
			int? userId = null;
			var user = this.UserResolver.Resolve();
			if(user != null)
			{
				userId = user.UserId;
			}

			var recipe = this.Repository.GetSet<Recipe>()
				.Include(x => x.Fermentables.Select(y => y.Fermentable))
				.Include(x => x.Hops.Select(y => y.Hop))
				.Include(x => x.Yeasts.Select(y => y.Yeast))
                .Include(x => x.Adjuncts.Select(y => y.Adjunct))
                .Include(x => x.MashSteps.Select(y => y.MashStep))
                .Include(x => x.BjcpStyleSummary)
				.Include(x => x.Steps)
				.Include(x => x.RecipeMetaData)
				.Where(x => x.IsActive)
				.Where(x => x.IsPublic || (userId != null && x.CreatedBy == userId))
				.FirstOrDefault(x => x.RecipeId == recipeId);

			if(recipe == null)
			{
				return null;
			}

			// Order Ingredients
			recipe.Fermentables = recipe.Fermentables.OrderBy(x => x.Rank).ToList();
			recipe.Hops = recipe.Hops.OrderBy(x => x.Rank).ToList();
			recipe.Adjuncts = recipe.Adjuncts.OrderBy(x => x.Rank).ToList();
			recipe.Yeasts = recipe.Yeasts.OrderBy(x => x.Rank).ToList();

			return recipe;
		}

		/// <summary>
		/// Adds a new Recipe
		/// </summary>
		public void AddNewRecipe(Recipe newRecipe)
		{
			if(newRecipe == null)
			{
				throw new ArgumentNullException("newRecipe");
			}

			var allIngredients = newRecipe.Fermentables
				.Union<IRecipeIngredient>(newRecipe.Hops)
				.Union(newRecipe.Yeasts)
				.Union(newRecipe.Adjuncts);

			// Look for Existing Ingredients to Match Custom Entered Ones
			this.VerifyCustomIngredients(allIngredients.Where(x => x.GetIngredient() != null));

			// Infer the Recipe Type
			newRecipe.RecipeTypeId = (int)RecipeTypeInferer.Infer(newRecipe);
			
			newRecipe.CreatedBy = this.UserResolver.Resolve().UserId;
			newRecipe.DateCreated = DateTime.Now;

			// Set Step Date Created
			newRecipe.Steps.ForEach(x => x.DateCreated = DateTime.Now);

			this.Repository.Add(newRecipe);
		}

		/// <summary>
		/// Finalizes a recipe for saving
		/// </summary>
		public void FinalizeRecipe(Recipe recipe)
		{
			if (recipe == null)
			{
				throw new ArgumentNullException("recipe");
			}

			var allIngredients = recipe.Fermentables
				.Union<IRecipeIngredient>(recipe.Hops)
				.Union(recipe.Yeasts)
				.Union(recipe.Adjuncts)
                .Union(recipe.MashSteps);

			// Look for Existing Ingredients to Match Custom Entered Ones
			this.VerifyCustomIngredients(allIngredients.Where(x => x.IngredientId <= 0));

			// Infer the Recipe Type
			recipe.RecipeTypeId = (int)RecipeTypeInferer.Infer(recipe);

			// Assume Active and Public by Default
			recipe.IsActive = true;
			recipe.IsPublic = true;

			// If Lacking Ingredients, Keep Private (not public)
			// But Not for Recipes with Existing Sessions or Comments or Clones
			if(recipe.RecipeMetaData == null || recipe.RecipeMetaData.BrewSessionCount == 0 && recipe.RecipeMetaData.CommentCount == 0 && recipe.RecipeMetaData.CloneCount == 0)
			{
				if(!recipe.Fermentables.Any(x => x.Amount > 0) || !recipe.Yeasts.Any())
				{
					recipe.IsPublic = false;
				}
			}

			if(recipe.IsNewRecipe())
			{
				recipe.CreatedBy = this.UserResolver.Resolve().UserId;
				recipe.DateCreated = DateTime.Now;

				// Set Step Date Created
				if(recipe.Steps != null)
				{
					recipe.Steps.ForEach(x => x.DateCreated = DateTime.Now);
				}
			}
			else
			{
				recipe.DateModified = DateTime.Now;
			}

			// Add New Recipes to Repo
			if(recipe.IsNewRecipe())
			{
				this.Repository.Add(recipe);
			}

		}

		/// <summary>
		/// Marks recipe ingredients for deletion
		/// </summary>
		public void MarkRecipeIngredientsForDeletion<TIngredientType>(IEnumerable<IRecipeIngredient> recipeIngredients) where TIngredientType : class, IRecipeIngredient
		{
			if(recipeIngredients == null)
			{
				throw new ArgumentNullException("recipeIngredients");
			}

			recipeIngredients.ForEach(x => this.Repository.Delete(x as TIngredientType));
		}

		/// <summary>
		/// Marks Recipe Steps for deletion
		/// </summary>
		public void MarkRecipeStepsForDeletion(List<RecipeStep> stepsForDeletion)
		{
			if(stepsForDeletion == null)
			{
				throw new ArgumentNullException("stepsForDeletion");
			}

			stepsForDeletion.ForEach(x => this.Repository.Delete(x));
		}

		/// <summary>
		/// Gets a list of user Recipes
		/// </summary>
		public IList<RecipeSummary> GetUserRecipes(int userId)
		{
			if(userId <= 0)
			{
				throw new ArgumentOutOfRangeException("userId");
			}

			return this.Repository.GetSet<RecipeSummary>()
                .Include(x => x.RecipeComments)
				.Where(x => x.CreatedBy == userId)
                .Where(x => x.IsActive)
				//.Where(x => x.IsPublic) // 
				.OrderByDescending(x => x.DateCreated)
				.ThenByDescending(x => x.DateModified)
				.ToList();
		}

		/// <summary>
		/// Gets a list of recent recipes
		/// </summary>
		public IList<RecipeSummary> GetRecentRecipesCached()
		{
            return GetRecentRecipesCached(3);
		}

		/// <summary>
		/// Gets a list of recent recipes
		/// </summary>
		public IList<RecipeSummary> GetNewestRecipes(int numberToReturn)
		{
			return this.Repository.GetSet<RecipeSummary>()
                .Include(x => x.RecipeComments)
				.Where(x => x.IsActive && x.IsPublic)
				.OrderByDescending(x => x.DateCreated)
				.Take(numberToReturn)
				.ToList();
		}

		/// <summary>
        /// Gets a list of recent recipes
        /// </summary>
        public IList<RecipeSummary> GetRecentRecipesCached(int numberToReturn)
        {
			var func = new Func<IList<RecipeSummary>>(() =>
			{
				return this.Repository.GetSet<RecipeSummary>()
                    .Include(x => x.RecipeComments)
					.Where(x => x.IsActive && x.IsPublic)
					.Where(x => x.ImageUrlRoot != null)
					.OrderByDescending(x => x.DateCreated)
					.Take(numberToReturn)
					.ToList();			                                          	
			});

			var result = this.CachingService.Get("RecentRecipes", AbsoluteCacheExpirationSettings.Make(15), func);

			return result.Take(numberToReturn).ToList();
        }

		/// <summary>
		/// Gets all Recipes.  Use with caution.
		/// </summary>
		public IList<Recipe> GetAllRecipes()
		{
			return this.Repository.GetSet<Recipe>()
				.Include(x => x.BjcpStyle)
				.Where(x => x.IsActive)
				.Where(x => x.IsPublic)
				.OrderByDescending(x => x.DateCreated)
				.ThenByDescending(x => x.DateModified)
				.ToList();
		}

		/// <summary>
		/// Verifies custom ingredients by comparing them with existing ingredients
		/// </summary>
		void VerifyCustomIngredients(IEnumerable<IRecipeIngredient> recipeIngredients)
		{
			var userId = this.UserResolver.Resolve().UserId;

			// If the custom ingredients macth an ingredient in the database, we omit creating a new
			// one and simply set the ID on the ingredient
			foreach(var recipeIngredient in recipeIngredients)
			{
				var ingredientId = this.RecipeDataService.FindIngredientId(recipeIngredient.GetIngredient(), userId);
				if(ingredientId.HasValue)
				{
					recipeIngredient.IngredientId = ingredientId.Value;
					recipeIngredient.SetIngredient(null);
				}
			}
		}

        /// <summary>
        /// Adds a new RecipeComment
        /// </summary>
        public void AddRecipeComment(RecipeComment recipeComment)
        {
            if (recipeComment == null)
            {
                throw new ArgumentNullException("recipeComment");
            }

            recipeComment.UserId = this.UserResolver.Resolve().UserId;
            recipeComment.DateCreated = DateTime.Now;
            recipeComment.IsActive = true;

            this.Repository.Add(recipeComment);
        }

        /// <summary>
        /// Adds a new BrewSessionComment
        /// </summary>
        public void AddBrewSessionComment(BrewSessionComment brewSessionComment)
        {
            if (brewSessionComment == null)
            {
                throw new ArgumentNullException("brewSessionComment");
            }

            brewSessionComment.UserId = this.UserResolver.Resolve().UserId;
            brewSessionComment.DateCreated = DateTime.Now;
            brewSessionComment.IsActive = true;

            this.Repository.Add(brewSessionComment);
        }

		/// <summary>
		/// Deletes a Recipe
		/// </summary>
		public void DeleteRecipe(Recipe recipe)
		{
			if (recipe == null)
			{
				throw new ArgumentNullException("recipe");
			}

			foreach (var brewSession in recipe.BrewSessions)
			{
				brewSession.IsActive = false;
			}

			recipe.IsActive = false;
			recipe.IsPublic = false;
			recipe.DateModified = DateTime.Now;
		}

		/// <summary>
		/// Edits a Recipe
		/// </summary>
		public void EditRecipe(Recipe recipe)
		{
			if(recipe == null)
			{
				throw new ArgumentNullException("recipe");	
			}

			recipe.DateModified = DateTime.Now;
			recipe.RecipeTypeId = (int)RecipeTypeInferer.Infer(recipe);
		}

		/// <summary>
		/// Gets the Comments for a Recipe
		/// </summary>
		public IList<RecipeCommentSummary> GetRecipeComments(int recipeId)
		{
			if(recipeId <= 0)
			{
				throw new ArgumentOutOfRangeException("recipeId");
			}

			return this.Repository.GetSet<RecipeCommentSummary>()
				.Where(x => x.RecipeId == recipeId)
				.ToList();
		}

        /// <summary>
        /// Gets the Comments for a BrewSession
        /// </summary>
        public IList<BrewSessionComment> GetBrewSessionComments(int brewSessionId)
        {
            if (brewSessionId <= 0)
            {
                throw new ArgumentOutOfRangeException("brewSessionId");
            }

            return this.Repository.GetSet<BrewSessionComment>()
                .Where(x => x.BrewSessionId == brewSessionId)
                .ToList();
        }

		/// <summary>
		/// Gets a RecipeSummary by Id
		/// </summary>
		public RecipeSummary GetRecipeSummaryById(int recipeId)
		{
			if(recipeId <= 0)
			{
				throw new ArgumentOutOfRangeException("recipeId");
			}

			return this.Repository.GetSet<RecipeSummary>()
                .Include(x => x.RecipeComments)
				.FirstOrDefault(x => x.RecipeId == recipeId);
		}

		/// <summary>
		/// Adds a new Recipe Brew
		/// </summary>
		public void AddNewBrewSession(BrewSession brewSession)
		{
			if(brewSession == null)
			{
				throw new ArgumentNullException("brewSession");
			}

			brewSession.UserId = this.UserResolver.Resolve().UserId;
			brewSession.DateCreated = DateTime.Now;
			brewSession.IsActive = true;
			brewSession.IsPublic = true;

			this.Repository.Add(brewSession);
		}

		/// <summary>
		/// Gets a BrewSession by Id
		/// </summary>
		public BrewSession GetBrewSessionById(int brewSessionId)
		{
			if(brewSessionId <= 0)
			{
				throw new ArgumentOutOfRangeException("brewSessionId");
			}

			return this.Repository.GetSet<BrewSession>()
				.Include(x => x.TastingNotes)
				.Where(x => x.BrewSessionId == brewSessionId)
				.Where(x => x.IsActive)
				.Where(x => x.IsPublic)
				.FirstOrDefault();
		}

		/// <summary>
		/// Adds a new BrewSessionTastingNote
		/// </summary>
		public void AddNewTastingNote(TastingNote tastingNote)
		{
			if (tastingNote == null)
			{
				throw new ArgumentNullException("tastingNote");
			}

			tastingNote.UserId = this.UserResolver.Resolve().UserId;
			tastingNote.DateCreated = DateTime.Now;
			tastingNote.IsActive = true;
			tastingNote.IsPublic = true;

			this.Repository.Add(tastingNote);
		}

		/// <summary>
		/// Gets a list of user recipe brews
		/// </summary>
		public IList<BrewSessionSummary> GetUserBrewSessions(int userId)
		{
			if(userId <= 0)
			{
				throw new ArgumentOutOfRangeException("userId");
			}

			return this.Repository.GetSet<BrewSessionSummary>()
                .Include(x => x.BrewSessionComments)
				.Where(x => x.IsActive)
				.Where(x => x.IsPublic)
				.Where(x => x.BrewedBy == userId)
				.OrderByDescending(x => x.BrewDate)
				.ToList();
		}

		/// <summary>
		/// Deletes a BrewSession
		/// </summary>
		public void DeleteBrewSession(BrewSession brewSession)
		{
			if(brewSession == null)
			{
				throw new ArgumentNullException("brewSession");
			}

			brewSession.IsActive = false;
			brewSession.IsPublic = false;
			brewSession.DateModified = DateTime.Now;
		}

		/// <summary>
		/// Gets a list of Recipe Brew Summaries for a Recipe
		/// </summary>
		public IList<BrewSessionSummary> GetRecipeBrewSessions(int recipeId)
		{
			if(recipeId <= 0)
			{
				throw new ArgumentOutOfRangeException("recipeId");
			}

			return this.Repository.GetSet<BrewSessionSummary>()
                .Include(x => x.BrewSessionComments)
				.Where(x => x.RecipeId == recipeId)
				.Where(x => x.IsActive)
				.ToList();
		}

		/// <summary>
		/// Deletes a brewSessionTastingNote
		/// </summary>
		public void DeleteTastingNote(TastingNote tastingNote)
		{
			if (tastingNote == null)
			{
				throw new ArgumentNullException("tastingNote");
			}

			tastingNote.DateModified = DateTime.Now;
			tastingNote.IsActive = false;
		}

		
        /// <summary>
        /// Gets a list of recent recipe brews
        /// </summary>
        public IList<BrewSessionSummary> GetNewestBrewSessions(int numberToReturn)
        {
            return this.Repository.GetSet<BrewSessionSummary>()
                .Include(x => x.BrewSessionComments)
                .Where(x => x.IsActive && x.IsPublic)
                .OrderByDescending(x => x.DateCreated)
                .Take(numberToReturn)
                .ToList();
        }

		/// <summary>
		/// Gets the count of Brew Sessions (BrewSession) for a Recipe
		/// </summary>
		/// <returns></returns>
		public int GetRecipeBrewSessionsCount(int recipeId)
		{
			if(recipeId <= 0)
			{
				throw new ArgumentOutOfRangeException("recipeId");
			}

			return this.Repository.GetSet<BrewSession>()
				.Count(x => x.RecipeId == recipeId && x.IsActive);
		}

		/// <summary>
		/// Gets all recipe brew summaries
		/// </summary>
		public IList<BrewSessionSummary> GetAllBrewSessionSummaries()
		{
			return this.Repository.GetSet<BrewSessionSummary>()
                .Include(x => x.BrewSessionComments)
				.Where(x => x.IsActive)
				.OrderByDescending(x => x.DateCreated)
				.ThenByDescending(x => x.DateModified)
				.ToList();
		}

		/// <summary>
		/// Gets a list of similar recipes
		/// </summary>
		public IList<RecipeSummary> GetSimilarRecipes(Recipe recipe, int count)
		{
			if (recipe == null)
			{
				throw new ArgumentNullException("recipe");
			}

			if (count <= 0)
			{
				throw new ArgumentOutOfRangeException("count");
			}

			int? currentUserId = null;
			var user = this.UserResolver.Resolve();
			if (user != null)
			{
				currentUserId = user.UserId;
			}

			return this.Repository.GetSet<RecipeSummary>()
                .Include(x => x.RecipeComments)
				.Where(x =>
					// Different Recipe that is Public and Active
					recipe.RecipeId != x.RecipeId && x.IsActive && x.IsPublic
					&&
					// Not created by current user
					(currentUserId == null || x.CreatedBy != currentUserId)
					&&
					(
						// +/- 10 IBU
						(recipe.Ibu > (x.Ibu - 10) && recipe.Ibu < (x.Ibu + 10))
						&&
						// SRM
						(recipe.Srm > (x.Srm - 5) && recipe.Srm < (x.Srm + 5))
						&&
						// OG
						((recipe.Og * 1000) > ((x.Og * 1000) - 5) && (recipe.Og * 1000) < ((x.Og * 1000) + 5))
						&&
						// Calories
						(recipe.Calories > (x.Calories - 10) && recipe.Calories < (x.Calories + 10))
						||
						(recipe.BjcpStyleSubCategoryId != null && x.BjcpStyleSubCategoryId == recipe.BjcpStyleSubCategoryId)
					) 
				)
				.OrderByDescending(x => x.DateCreated)
				.Take(count)
				.ToList();
		}

		/// <summary>
		/// Gets a list of the most popular recipes
		/// </summary>
		public IList<RecipeSummary> GetPopularRecipes(int count)
		{
			var startDate = DateTime.Now.AddDays(-7);

			return this.Repository.GetSet<Recipe>()
                .Include(x => x.RecipeComments)
				.Where(x => x.IsActive && x.IsPublic)
				.Where(x => x.RecipeComments.Any())
				.OrderByDescending(x => x.RecipeComments.Count(y => y.DateCreated >= startDate))
				.Select(x => x.RecipeSummary)
				.Take(count)
				.ToList();
		}

        /// <summary>
        ///  Gets the object ids for the dashboard
        /// </summary>
        public DashboardItemHolder GetDashboardItems(int userId, DateTime searchOlderThan, int numberToReturn)
        {
            if (userId <= 0)
            {
                throw new ArgumentOutOfRangeException("userId");
            }

            var objectIdsForDashboard = this.GetObjectIdsForDashboard(userId, searchOlderThan, numberToReturn);

            IList<RecipeSummary> recipeMatches = null;
            IList<BrewSessionSummary> brewSessionMatches  = null;
            IList<TastingNoteSummary> tastingNoteMatches  = null;
            
            Parallel.Invoke(
            // Recipes
            () =>
            {
                recipeMatches = this.Repository.GetSet<RecipeSummary>()
                    .Include(x => x.RecipeComments)
                    .WhereIn(x => x.RecipeId, objectIdsForDashboard["Recipe"])
                    .ToList();
            },
            // BrewSessions
            () =>
            {
                brewSessionMatches = this.Repository.GetSet<BrewSessionSummary>()
                   .Include(x => x.BrewSessionComments)
                   .WhereIn(x => x.BrewSessionId, objectIdsForDashboard["BrewSession"])
                   .ToList();
            },
	        () =>
	        {
				tastingNoteMatches = this.Repository.GetSet<TastingNoteSummary>()
				.WhereIn(x => x.TastingNoteId, objectIdsForDashboard["TastingNote"])
				.ToList();
	        }
			);

            return new DashboardItemHolder
            {
                RecipeSummaries = recipeMatches,
                BrewSessionSummaries = brewSessionMatches,
				TastingNoteSummaries = tastingNoteMatches
            };
        }

		/// <summary>
		/// Gets the appropriate recipe creation options
		/// </summary>
		public RecipeCreationOptions GetRecipeCreationOptions()
		{
			var recipeCreationOptions = new RecipeCreationOptions();

			// Determine Current User
			int? userId = null;
			var user = this.UserResolver.Resolve();
			if (user != null)
			{
				userId = user.UserId;
			}

			// Beer Styles
			recipeCreationOptions.StyleGroups = this.BeerStyleService.GetStyleSummaries().OrderBy(x => x.CategoryId)
				.ThenBy(x => x.SubCategoryId)
				.GroupBy(x => new { x.CategoryId, x.CategoryName })
				.Select(y => new BjcpStyleGroup
				{
					CategoryId = y.Key.CategoryId,
					CategoryName = y.Key.CategoryName,
					BjcpStyleSummaries = y.ToList()
				})
				 .ToList();

			// Fetch Ingredients for the User Id
			recipeCreationOptions.Fermentables = this.RecipeDataService.GetUsableIngredients<Fermentable>(userId).OrderBy(x => x.Name).ToList();
			recipeCreationOptions.Hops = this.RecipeDataService.GetUsableIngredients<Hop>(userId).OrderBy(x => x.Name).ToList();
			recipeCreationOptions.YeastGroups = this.IngredientCategorizer.Categorize(this.RecipeDataService.GetUsableIngredients<Yeast>(userId)).ToList();
			recipeCreationOptions.Adjuncts = this.RecipeDataService.GetUsableIngredients<Adjunct>(userId).ToList();
			recipeCreationOptions.MashSteps = this.RecipeDataService.GetUsableIngredients<MashStep>(userId).ToList();

			// Set Send to Shop Settings
			recipeCreationOptions.SendToShopSettings = this.SendToShopService.GetRecipeCreationSendToShopSettings() ?? new RecipeCreationSendToShopSettings();

			return recipeCreationOptions;
		}

		/// <summary>
		/// Gets the most recent brew session
		/// </summary>
		public int? GetMostRecentBrewSession(int recipeId)
		{
			return this.Repository.GetSet<BrewSession>()
				.Where(x => x.RecipeId == recipeId)
				.Where(x => x.IsActive)
				.Where(x => x.IsPublic)
				.OrderByDescending(x => x.BrewDate)
				.Select(x => x.BrewSessionId)
				.Cast<int?>()
				.FirstOrDefault();
		}

		/// <summary>
		/// Gets a list of tasting notes for a recipe
		/// </summary>
		public IList<TastingNote> GetRecipeTastingNotes(int recipeId)
		{
			if(recipeId <= 0)
			{
				throw new ArgumentOutOfRangeException("recipeId");
			}

			return this.Repository.GetSet<TastingNote>()
				.Include(x => x.User)
				.Where(x => x.IsActive)
				.Where(x => x.IsPublic)
				.Where(x => x.BrewSession.RecipeId == recipeId  || x.RecipeId == recipeId)
				.OrderByDescending(x => x.TasteDate)
				.ToList();
		}

		/// <summary>
		/// Gets a tasting note
		/// </summary>
		public TastingNote GetTastingNote(int tastingNoteId)
		{
			if(tastingNoteId <= 0)
			{
				throw new ArgumentOutOfRangeException("tastingNoteId");
			}

			return this.Repository.GetSet<TastingNote>()
				.FirstOrDefault(x => x.TastingNoteId == tastingNoteId);
		}

		/// <summary>
		/// Checks is the current users is allowed to perform a tasting note submission
		/// </summary>
		public bool AllowTastingNoteSubmission(TastingNote tastingNote)
		{
			// TODO: Allow invitation tasting note submissions
			// TODO: Allow invitation tasting note submissions
			// TODO: Allow invitation tasting note submissions
			// TODO: Allow invitation tasting note submissions
			var user = this.UserResolver.Resolve();
			if(tastingNote.TastingNoteId > 0)
			{
				return user.UserId == tastingNote.UserId;
			}
			else
			{
				return this.Repository.GetSet<Recipe>()
					.Any(x => tastingNote.RecipeId != null && x.RecipeId == tastingNote.RecipeId)
						||
					this.Repository.GetSet<BrewSession>()
						.Any(x => tastingNote.BrewSessionId != null && x.BrewSessionId == tastingNote.BrewSessionId);
			}
		}

		/// <summary>
		/// Gets a list of recipes that appear to be clones of a popular recipes
		/// </summary>
		public IList<RecipeSummary> GetPopularRecipeClones(string cloneNameLoookup)
		{
			if(string.IsNullOrWhiteSpace(cloneNameLoookup))
			{
				throw new ArgumentNullException("cloneNameLoookup");
			}

			return this.Repository.GetSet<RecipeSummary>()
				.Where(x => x.IsActive)
				.Where(x => x.IsPublic)
				.Where(x => !x.RecipeName.StartsWith("Clone of"))
				.Where(x => x.RecipeName.Contains(cloneNameLoookup))
				.ToList();
		}

		/// <summary>
        /// Gets the object ids for the dashboard
        /// </summary>
        Dictionary<string, List<int>> GetObjectIdsForDashboard(int userId, DateTime searchOlderThan, int numberToReturn)
        {
            if (userId <= 0)
            {
                throw new ArgumentOutOfRangeException("userId");
            }

            IDataProvider provider = DataProviderFactory.Make(this.DataContextActivationInfo.ProviderName);

            using(var command = StoredProcedureCommand.Make(provider, "dbo.\"GetObjectIdsForDashboard\"")
		        .UsingConnection(this.DataContextActivationInfo.ConnectionString)
		        .WithParam("@UserId", userId)
		        .WithParam("@Amount", numberToReturn)
		        .WithParam("@OlderThanDate", searchOlderThan))
		    {
                var results = command.GetDataSet();

                var dictionary = new Dictionary<string, List<int>>();

                // if no results just grab the newest recipes and brews
                if (results.Tables[0].Rows.Count < 1)
                {
                    var resultsNewest = StoredProcedureCommand.Make(provider, "dbo.\"GetObjectIdsForDashboardNewest\"")
                        .UsingConnection(this.DataContextActivationInfo.ConnectionString)
                        .WithParam("@Amount", numberToReturn)
                        .WithParam("@OlderThanDate", searchOlderThan)
                        .GetDataSet();

                    dictionary.Add("Recipe", resultsNewest.Tables[0].Rows.Cast<DataRow>().Where(x => x["Type"].ToString() == "Recipe").Select(x => Convert.ToInt32(x["Id"])).ToList());
                    dictionary.Add("BrewSession", resultsNewest.Tables[0].Rows.Cast<DataRow>().Where(x => x["Type"].ToString() == "BrewSession").Select(x => Convert.ToInt32(x["Id"])).ToList());
                    dictionary.Add("TastingNote", resultsNewest.Tables[0].Rows.Cast<DataRow>().Where(x => x["Type"].ToString() == "TastingNote").Select(x => Convert.ToInt32(x["Id"])).ToList());
                }
                else
                {
                    dictionary.Add("Recipe", results.Tables[0].Rows.Cast<DataRow>().Where(x => x["Type"].ToString() == "Recipe").Select(x => Convert.ToInt32(x["Id"])).ToList());
                    dictionary.Add("BrewSession", results.Tables[0].Rows.Cast<DataRow>().Where(x => x["Type"].ToString() == "BrewSession").Select(x => Convert.ToInt32(x["Id"])).ToList());
                    dictionary.Add("TastingNote", results.Tables[0].Rows.Cast<DataRow>().Where(x => x["Type"].ToString() == "TastingNote").Select(x => Convert.ToInt32(x["Id"])).ToList());
                }

                return dictionary;
            }            
        }
	}
}