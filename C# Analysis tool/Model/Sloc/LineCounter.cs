using System.Collections.Generic;

namespace CSharpInheritanceAnalyzer.Model.Sloc
{
    public static class LineCounter
    {
        public static LineCountResult CountLines(IEnumerable<string> file)
        {
            bool inMultilineComment = false;
            int codeCount = 0, commentCount = 0, blankCount = 0;
            foreach (string line in file)
            {
                bool lineHasCode = false;
                bool inComment = false;
                bool lineHasComment = inMultilineComment;
                for (int i = 0; i < line.Length; i++)
                {
                    char c = line[i];
                    if (c == '/')
                    {
                        if (i < line.Length - 1)
                        {
                            char next = line[i + 1];
                            if (next == '/' && !inMultilineComment)
                            {
                                lineHasComment = true;
                                goto eol;
                            }
                            if (next == '*')
                            {
                                inComment = true;
                                inMultilineComment = true;
                                lineHasComment = true;
                            }
                        }
                    }
                    else
                    {
                        if (i < line.Length - 1 && c == '*')
                        {
                            char next = line[i + 1];
                            if (next == '/')
                            {
                                lineHasComment = true;
                                inComment = false;
                                inMultilineComment = false;
                            }
                        }
                        else if (!char.IsWhiteSpace(c) && !inComment && !inMultilineComment)
                        {
                            lineHasCode = true;
                        }
                    }
                }
                eol:
                if (lineHasCode)
                {
                    codeCount++;
                }
                else if (lineHasComment)
                {
                    commentCount++;
                }
                else
                {
                    blankCount++;
                }
            }
            return new LineCountResult(codeCount, commentCount, blankCount);
        }
    }

    public class LineCountResult
    {
        private readonly int _blankCount;
        private readonly int _codeCount;
        private readonly int _commentCount;

        public static LineCountResult operator +(LineCountResult left, LineCountResult right)
        {
            return new LineCountResult(left.CodeCount + right.CodeCount, left.CommentCount + right.CommentCount,
                left.BlankCount + right.BlankCount);
        }

        public LineCountResult(int codeCount, int commentCount, int blankCount)
        {
            _codeCount = codeCount;
            _commentCount = commentCount;
            _blankCount = blankCount;
        }

        public int CodeCount
        {
            get { return _codeCount; }
        }

        public int CommentCount
        {
            get { return _commentCount; }
        }

        public int BlankCount
        {
            get { return _blankCount; }
        }

        public override string ToString()
        {
            return string.Format("{0} LOC, {1} Comment", CodeCount, CommentCount);
        }
    }
}