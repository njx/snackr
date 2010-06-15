package tests.unittests
{
	import flexunit.framework.Assert;
	import flexunit.framework.TestCase;
	import flexunit.framework.TestSuite;
	
	import model.utils.FeedUtils;

	public class FeedUtilsTest extends TestCase
	{
		public function FeedUtilsTest(methodName: String = null)
		{
			super(methodName);
		}
		
		static public function suite(): TestSuite {
			var ts: TestSuite = new TestSuite();
			ts.addTest(new FeedUtilsTest("testResolveURL"));
			ts.addTest(new FeedUtilsTest("testFixupFeedURL"));
			return ts;
		}
		
		static private var _resolveURLKnownGoods: Array = [
			{url: "http://test.com/feed.xml", docBase: "http://foo.com", result: "http://test.com/feed.xml"},
			{url: "/feed.xml", docBase: "http://test.com", result: "http://test.com/feed.xml"},
			{url: "/feed.xml", docBase: "http://test.com/", result: "http://test.com/feed.xml"},
			{url: "/feed.xml", docBase: "http://test.com/index.html", result: "http://test.com/feed.xml"},
			{url: "/feed.xml", docBase: "http://test.com/subdir/", result: "http://test.com/feed.xml"},
			{url: "/feed.xml", docBase: "http://test.com/subdir/index.html", result: "http://test.com/feed.xml"},
			{url: "/feeds/feed.xml", docBase: "http://test.com", result: "http://test.com/feeds/feed.xml"},
			{url: "/feeds/feed.xml", docBase: "http://test.com/", result: "http://test.com/feeds/feed.xml"},
			{url: "/feeds/feed.xml", docBase: "http://test.com/index.html", result: "http://test.com/feeds/feed.xml"},
			{url: "/feeds/feed.xml", docBase: "http://test.com/subdir/", result: "http://test.com/feeds/feed.xml"},
			{url: "/feeds/feed.xml", docBase: "http://test.com/subdir/index.html", result: "http://test.com/feeds/feed.xml"},
			{url: "feed.xml", docBase: "http://test.com", result: "http://test.com/feed.xml"},
			{url: "feed.xml", docBase: "http://test.com/", result: "http://test.com/feed.xml"},
			{url: "feed.xml", docBase: "http://test.com/index.html", result: "http://test.com/feed.xml"},
			{url: "feed.xml", docBase: "http://test.com/subdir/", result: "http://test.com/subdir/feed.xml"},
			{url: "feed.xml", docBase: "http://test.com/subdir/index.html", result: "http://test.com/subdir/feed.xml"},
			{url: "feeds/feed.xml", docBase: "http://test.com", result: "http://test.com/feeds/feed.xml"},
			{url: "feeds/feed.xml", docBase: "http://test.com/", result: "http://test.com/feeds/feed.xml"},
			{url: "feeds/feed.xml", docBase: "http://test.com/index.html", result: "http://test.com/feeds/feed.xml"},
			{url: "feeds/feed.xml", docBase: "http://test.com/subdir/", result: "http://test.com/subdir/feeds/feed.xml"},
			{url: "feeds/feed.xml", docBase: "http://test.com/subdir/index.html", result: "http://test.com/subdir/feeds/feed.xml"}
		];
		
		public function testResolveURL(): void {
			for each (var knownGood: Object in _resolveURLKnownGoods) {
				Assert.assertEquals("resolveURL(" + knownGood.url + ", " + knownGood.docBase + ")", 
					FeedUtils.resolveURL(knownGood.url, knownGood.docBase), knownGood.result);
			}
		}
		
		static private var _fixupFeedURLKnownGoods: Array = [
			{url: "http://mytest.com/feed.xml", returnBlankIfInvalid: true, result: "http://mytest.com/feed.xml"},
			{url: "http://mytest.com/feed.xml", returnBlankIfInvalid: false, result: "http://mytest.com/feed.xml"},
			{url: "feed://mytest.com/feed.xml", returnBlankIfInvalid: true, result: "http://mytest.com/feed.xml"},
			{url: "feed://mytest.com/feed.xml", returnBlankIfInvalid: false, result: "http://mytest.com/feed.xml"},
			{url: "mytest.com/feed.xml", returnBlankIfInvalid: true, result: "http://mytest.com/feed.xml"},
			{url: "mytest.com/feed.xml", returnBlankIfInvalid: false, result: "http://mytest.com/feed.xml"},
			{url: "mytest/feed.xml", returnBlankIfInvalid: true, result: "http://mytest/feed.xml"},			
			{url: "mytest/feed.xml", returnBlankIfInvalid: false, result: "http://mytest/feed.xml"},
			{url: "not a URL", returnBlankIfInvalid: true, result: ""},
			{url: "not a URL", returnBlankIfInvalid: false, result: "not a URL"}
		];
		
		public function testFixupFeedURL(): void {
			for each (var knownGood: Object in _fixupFeedURLKnownGoods) {
				Assert.assertEquals("fixupFeedURL(" + knownGood.url + ", " + knownGood.returnBlankIfInvalid + ")", 
					FeedUtils.fixupFeedURL(knownGood.url, knownGood.returnBlankIfInvalid), knownGood.result);
			}			
		}
	}
}