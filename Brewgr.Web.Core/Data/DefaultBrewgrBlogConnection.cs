using System;

namespace Brewgr.Web.Core.Data
{
    public class DefaultBrewgrBlogConnection : IBrewgrBlogConnection
    {
        /// <summary>
        /// Gets the connection string
        /// </summary>
        public string ConnectionString
        {
            get
            {
                return Environment.GetEnvironmentVariable("BrewgrBlog_ConnectionString");
            }
        }

        /// <summary>
        /// Gets the provider name
        /// </summary>
        public string ProviderName
        {
            get
            {
                // TODO Generalize the blog search SQL before accepting additional providers with
                // return Environment.GetEnvironmentVariable("BrewgrBlog_ProviderName");
                return "SqlClient";
            }
        }
    }
}