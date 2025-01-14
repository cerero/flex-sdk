package mx.collections
{
    import flash.events.UncaughtErrorEvent;

import flashx.textLayout.debug.assert;

import mx.collections.ArrayCollection;
    import mx.collections.CursorBookmark;
    import mx.collections.HierarchicalCollectionView;
    import mx.collections.HierarchicalCollectionViewCursor;
    import mx.core.FlexGlobals;
    
    import spark.components.WindowedApplication;
    
    import org.flexunit.asserts.assertEquals;

    public class HierarchicalCollectionViewCursor_Basics_Test
	{
		private static var _utils:HierarchicalCollectionViewTestUtils = new HierarchicalCollectionViewTestUtils();
		private static var _currentHierarchy:HierarchicalCollectionView;
		private static var _noErrorsThrown:Boolean = true;
		private var _level0:ArrayCollection;
		
		private var _sut:HierarchicalCollectionViewCursor;
		
		[BeforeClass]
		public static function setUpBeforeClass():void
		{
			(FlexGlobals.topLevelApplication as WindowedApplication).loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, handleUncaughtClientError);
		}
		
		[AfterClass]
		public static function tearDownAfterClass():void
		{
			(FlexGlobals.topLevelApplication as WindowedApplication).loaderInfo.uncaughtErrorEvents.removeEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, handleUncaughtClientError);
		}
		
		[Before]
		public function setUp():void
		{
            _currentHierarchy = generateHierarchyViewWithOpenNodes();
            _level0 = _utils.getRoot(_currentHierarchy) as ArrayCollection;
            _sut = _currentHierarchy.createCursor() as HierarchicalCollectionViewCursor;

			_noErrorsThrown = true;
		}
		
		[After]
		public function tearDown():void
		{
			_sut = null;
            _currentHierarchy = null;
            _level0 = null;
		}



        [Test]
        public function testMovingAround():void
        {
            //given
            var lastCompany:DataNode = _level0.getItemAt(_level0.length - 1) as DataNode;
            var firstCompany:DataNode = _level0.getItemAt(0) as DataNode;
            var firstLocation:DataNode = firstCompany.children.getItemAt(0) as DataNode;
            var secondLocation:DataNode = firstCompany.children.getItemAt(1) as DataNode;
            var firstDepartment:DataNode = firstLocation.children.getItemAt(0) as DataNode;
            var secondDepartment:DataNode = firstLocation.children.getItemAt(1) as DataNode;

            //when
            _sut.moveNext();

            //then
            assertEquals(firstLocation, _sut.current);

            //when
            _sut.moveNext();

            //then
            assertEquals(firstDepartment, _sut.current);

            //when
            _sut.moveNext();

            //then
            assertEquals(secondDepartment, _sut.current);

            //when
            _sut.movePrevious();

            //then
            assertEquals(firstDepartment, _sut.current);

            //when
            _sut.moveToLast();

            //then
            assertEquals(lastCompany, _sut.current);

            //when
            _sut.seek(new CursorBookmark(4));

            //then
            assertEquals(secondLocation, _sut.current);
        }

        [Test]
        public function testCollectionChangeInRootDoesNotChangeCurrent():void
        {
            //given
            var lastCompany:DataNode = _level0.getItemAt(_level0.length - 1) as DataNode;

            //when
            _sut.moveToLast();

            var newFirstCompany:DataNode = _utils.createSimpleNode("[INS] Company");
            _level0.addItemAt(newFirstCompany, 0);

            var newLastCompany:DataNode = _utils.createSimpleNode("[INS] Company");
            _level0.addItemAt(newLastCompany, _level0.length);

            //then
            assertEquals(lastCompany, _sut.current);

            //when
            _sut.moveToLast();

            //then
            assertEquals(newLastCompany, _sut.current);
        }

        [Test]
        public function testRemovingCurrentMiddleItemChangesCurrentToNextItem():void
        {
            //given
            var firstCompany:DataNode = _level0.getItemAt(0) as DataNode;
            var secondLocation:DataNode = firstCompany.children.getItemAt(1) as DataNode;
            var thirdDepartmentOfSecondLocation:DataNode = secondLocation.children.getItemAt(2) as DataNode;

            _sut.seek(new CursorBookmark(6)); //Company(1)->Location(2)->Department(2)

            //when
            secondLocation.children.removeItemAt(1);

            //then
            assertEquals(thirdDepartmentOfSecondLocation, _sut.current);
        }

        [Test]
        public function testRemovingPreviousSiblingOfCurrentMiddleItemDoesNotChangeCurrent():void
        {
            //given
            var firstCompany:DataNode = _level0.getItemAt(0) as DataNode;
            var secondLocation:DataNode = firstCompany.children.getItemAt(1) as DataNode;
            var secondDepartmentOfSecondLocation:DataNode = secondLocation.children.getItemAt(1) as DataNode;

            //when
            _sut.seek(new CursorBookmark(6)); //Company(1)->Location(2)->Department(2)

            //then
            assertEquals(secondDepartmentOfSecondLocation, _sut.current);

            //when
            secondLocation.children.removeItemAt(0);

            //then
            assertEquals(secondDepartmentOfSecondLocation, _sut.current);
        }

        [Test]
        public function testRemovingCurrentFirstItemChangesCurrentToNextItem():void
        {
            //given
            var firstCompany:DataNode = _level0.getItemAt(0) as DataNode;
            var secondCompany:DataNode = _level0.getItemAt(1) as DataNode;

            //initial assumption
            assertEquals(firstCompany, _sut.current);

            //when
            _level0.removeItemAt(0);

            //then
            assertEquals(secondCompany, _sut.current);
        }

        [Test]
        public function testRemovingSiblingOfCurrentFirstItemDoesNotChangeCurrent():void
        {
            //given
            var firstCompany:DataNode = _level0.getItemAt(0) as DataNode;
            var firstLocation:DataNode = firstCompany.children.getItemAt(0) as DataNode;

            //when
            _sut.seek(new CursorBookmark(1)); //Company(1)->Location(1)

            //then
            assertEquals(firstLocation, _sut.current);

            //when
            firstCompany.children.removeItemAt(1);

            //then
            assertEquals(firstLocation, _sut.current);
        }
		
		
		private static function handleUncaughtClientError(event:UncaughtErrorEvent):void
		{
			event.preventDefault();
			event.stopImmediatePropagation();
			_noErrorsThrown = false;
			
			trace("\n" + event.error);
			_utils.printHCollectionView(_currentHierarchy);
		}

		
		private static function generateHierarchyViewWithOpenNodes():HierarchicalCollectionView
		{
			return _utils.generateOpenHierarchyFromRootList(_utils.generateHierarchySourceFromString(HIERARCHY_STRING));
		}

		private static const HIERARCHY_STRING:String = (<![CDATA[
			Company(1)
			Company(1)->Location(1)
			Company(1)->Location(1)->Department(1)
			Company(1)->Location(1)->Department(2)
			Company(1)->Location(2)
			Company(1)->Location(2)->Department(1)
			Company(1)->Location(2)->Department(2)
			Company(1)->Location(2)->Department(3)
			Company(1)->Location(3)
			Company(2)
			Company(2)->Location(1)
			Company(2)->Location(2)
			Company(2)->Location(2)->Department(1)
			Company(2)->Location(3)
			Company(3)
		]]>).toString();
	}
}