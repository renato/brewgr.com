    using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Brewgr.Web.Core.Model
{
    public class BjcpStyle
    {
		/// <summary>
		/// Gets or sets the Class
		/// </summary>
        public string Class { get; set; }

		/// <summary>
		/// Gets or sets the CategoryId
		/// </summary>
        public int CategoryId { get; set; }

		/// <summary>
		/// Gets or sets the CategoryName
		/// </summary>
        public string CategoryName { get; set; }
		
		/// <summary>
		/// Gets or sets the SubCategoryId
		/// </summary>
        public string SubCategoryId { get; set; }

		/// <summary>
		/// Gets or sets the Sub Category Name
		/// </summary>
        public string SubCategoryName { get; set; }

		/// <summary>
		/// Gets or sets the aroma
		/// </summary>
        public string Aroma { get; set; }

		/// <summary>
		/// Gete or sets the Apperance
		/// </summary>
        public string Appearance { get; set; }

		/// <summary>
		/// Gets or sets the flavor
		/// </summary>
        public string Flavor { get; set; }

		/// <summary>
		/// Gets or sets the mouthfeel
		/// </summary>
        public string Mouthfeel { get; set; }

		/// <summary>
		/// Gets or sets the impression
		/// </summary>
        public string Impression { get; set; }

		/// <summary>
		/// Gets or sets the comments
		/// </summary>
        public string Comments { get; set; }

		/// <summary>
		/// Gets or sets the ingredients
		/// </summary>
        public string Ingredients { get; set; }

		/// <summary>
		/// Gets or sets the OG Low
		/// </summary>
        public double? Og_Low { get; set; }

		/// <summary>
		/// Gets or sets the OG High
		/// </summary>
        public double? Og_High { get; set; }

		/// <summary>
		/// Gets or sets the FG Low
		/// </summary>
        public double? Fg_Low { get; set; }

		/// <summary>
		/// Gets or sets the FG High
		/// </summary>
        public double? Fg_High { get; set; }

		/// <summary>
		/// Gets or sets the IBU Low
		/// </summary>
        public int? Ibu_Low { get; set; }

		/// <summary>
		/// Gets or sets the IBU High
		/// </summary>
        public int? Ibu_High { get; set; }

		/// <summary>
		/// Gets or sets the SRM Low
		/// </summary>
        public double? Srm_Low { get; set; }

		/// <summary>
		/// Gets or sets the SRM High
		/// </summary>
        public double? Srm_High { get; set; }

		/// <summary>
		/// Gets or sets the ABV Low
		/// </summary>
        public double? Abv_Low { get; set; }

		/// <summary>
		/// Gets or sets the ABV High
		/// </summary>
        public double? Abv_High { get; set; }

		/// <summary>
		/// Gets or sets the examples
		/// </summary>
        public string Examples { get; set; }

    	/// <summary>
    	/// Gets or sets the Recipes
    	/// </summary>
    	public IList<Recipe> Recipes { get; set; }

    	/// <summary>
    	/// Gets or sets the BjcpStyleUrlFriendlyName
    	/// </summary>
    	public BjcpStyleUrlFriendlyName BjcpStyleUrlFriendlyName { get; set; }
    }
}
