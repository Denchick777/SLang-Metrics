using LanguageElements;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;

namespace Metrics
{
    class MaintainabilityIndex
    {
        private double value;

        /// Get Maintainability index based on formula used by Microsoft Visual Studio (since 2008)
        public MaintainabilityIndex(double HV, double CC, double LOC)
        {
            this.value = Math.Max(0,
                    (171 - 5.2 * Math.Log(HV, Math.E) - 0.23 * (CC) - 16.2 * Math.Log(LOC, Math.E)) * 100 / 171);
            // MAX(0,(171 - 5.2 * ln(Halstead Volume) - 0.23 * (Cyclomatic Complexity) - 16.2 * ln(Lines of Code))*100 / 171)
        }

        public double getValue()
        {
            return this.value;
        }
    }

    public class MetricCollector
    {
        // TODO: for now it accessible for testing purposes.
        // If future this class should provide features to extract info from Module @parsedModule
        internal Module parsedModule { get; }
        private MaintainabilityIndex maintIndex;
        private Traverse traverse;
        private InheritanceWrapper inheritance;

        public MetricCollector(string fileName)
        {
            this.parsedModule = SLangParser.Parser.parseProgram(fileName);

            if (parsedModule == null)
            {
                throw new ParsingFailedException();
            }
            this.maintIndex = new MaintainabilityIndex(
                    parsedModule.ssMetrics.volume, parsedModule.getCC(), parsedModule.ssMetrics.LOC);
            this.traverse = new Traverse(parsedModule);
            this.inheritance = new InheritanceWrapper(traverse.unitList);
        }

        public void ActivateInterface(string[] args)
        {
            // TODO: parse args and choose an appropriate interface
            ActivateCLI();
        }

        private void ActivateCLI()
        {
            string input;
            PrintInvitation();
            while (true)
            {
                Console.Write(">>> ");
                input = Console.ReadLine();

                switch (input.ToLower())
                {
                    case "inheritancetree":
                        inheritance.printTreeRepresentation();
                        break;

                    case "allunits":
                        Console.WriteLine(String.Join("\n", inheritance.getUnitNames().ToArray()));
                        break;

                    case "help":
                        PrintHelp();
                        break;

                    case "exit":
                        goto exit;

                    default:
                        ParseMetricQuery(input);
                        break;
                }
            }
        exit:
            Console.WriteLine("Terminating process...");
        }

        private void PrintInvitation()
        {
            Console.WriteLine(
                    "Your input was successfully parsed!\n" +
                    "Now you may ask for some metrics of the given code.\n"
            );
            PrintHelp();
            Console.WriteLine("\nWrite here your query:");
        }

        private void PrintHelp()
        {
            Console.WriteLine(
                "\thelp - print list of queries (this message)\n" +
                "\texit - quit and terminate this session\n" +
                "\t<MetricName> [<MetricArgs>] - print a value of a given metric"
            );
        }

        private void ParseMetricQuery(string input)
        {
            if (input.Length < 1)
            {
                return;
            }

            string[] split = input.Split().Where(s => s.Length > 0).ToArray();
            string metricName = split[0].ToLower();
            string[] args = split.Skip(1).ToArray();
            switch (metricName)
            {
                case "cc":
                case "cyclomaticcomplexity":
                    if (args.Length > 0)
                    {
                        RoutineDeclaration found = null;
                        foreach (RoutineDeclaration routine in traverse.routineList ?? Enumerable.Empty<RoutineDeclaration>())
                        {
                            if (routine.name.ToString().Equals(args[0]))
                            {
                                found = routine;
                                break;
                            }
                        }
                        if (found != null)
                        {
                            Console.WriteLine("Cyclomatic Complexity of routine {0}: {1}",
                                    args[0], found.getCC());
                        }
                        else
                        {
                            Console.WriteLine("Routine not found: {0}", args[0]);
                        }
                    }
                    else
                    {
                        Console.WriteLine("Cyclomatic Complexity of Module scope: {0}",
                                parsedModule.getCC());
                    }
                    break;

                case "ss":
                case "softwaresciences":
                    Console.WriteLine(
                        ""  // TODO: Pretty Print
                    );
                    break;

                case "mi":
                case "maintainabilityindex":
                    Console.WriteLine(
                        ""  // TODO: Pretty Print
                    );
                    break;

                case "wru":
                case "weightedroutines":
                case "weightedroutinesperunit":
                    if (args.Length > 0)
                    {
                        UnitDeclaration found = null;
                        foreach (UnitDeclaration unit in traverse.unitList ?? Enumerable.Empty<UnitDeclaration>())
                        {
                            if (unit.name.ToString().Equals(args[0]))
                            {
                                found = unit;
                                break;
                            }
                        }
                        if (found != null)
                        {
                            Console.WriteLine("Weighted Routines per Unit {0}: {1}",
                                    args[0], found.getWRU());
                        }
                        else
                        {
                            Console.WriteLine("Unit not found: {0}", args[0]);
                        }
                    }
                    else
                    {
                        Console.WriteLine("Please, specify unit name");
                    }
                    break;

                case "dit":
                case "depthofinheritancetree":
                    if (args.Length > 0)
                    {
                        try
                        {
                            Console.WriteLine("Hierarchy height of unit {0}: {1}",
                                    args[0], inheritance.getHierachyHeight(args[0]));
                        }
                        catch (NonExistantUnitException)
                        {
                            Console.WriteLine("Unit not found: {0}", args[0]);
                        }
                    }
                    else
                    {
                        Console.WriteLine(
                                "Maximal inheritance depth: " + inheritance.getMaxHierarchyHeight() +
                                "\nAverage inheritance depth: " + inheritance.getAverageHierarchyHeight()
                        );
                    }
                    break;

                case "nod":
                case "numberofdescendants":
                    if (args.Length > 0)
                    {
                        try
                        {
                            Console.WriteLine("Number of descendants of {0}: {1}",
                                    args[0], inheritance.getDescendantsCount(args[0]));
                        }
                        catch (NonExistantUnitException)
                        {
                            Console.WriteLine("Unit not found: {0}", args[0]);
                        }
                    }
                    else
                    {
                        Console.WriteLine("Please, specify unit name");
                    }
                    break;

                case "inheritancepaths":
                    if (args.Length > 0)
                    {
                        try
                        {
                            foreach (string path in inheritance.getHierarchyPaths(args[0]) ?? Enumerable.Empty<string>())
                            {
                                Console.WriteLine(path);
                            }
                        }
                        catch (NonExistantUnitException)
                        {
                            Console.WriteLine("Unit not found: {0}", args[0]);
                        }
                    }
                    else
                    {
                        Console.WriteLine("Please, specify unit name");
                    }
                    break;

                case "mhh":
                case "maximumhierarchyheight":
                    Console.WriteLine("Maximum Hierarchy Height: {0}", traverse.maxHH);
                    break;

                case "ahh":
                case "averagehierarchyheight":
                    Console.WriteLine("Average Hierarchy Height: {0}", traverse.averageHH);
                    break;

                default:
                    Console.WriteLine("Unknown metric: {0}", metricName);
                    break;
            }
        }
    }

    public class ParsingFailedException : Exception
    {
        public ParsingFailedException() : base() { }
    }
}
